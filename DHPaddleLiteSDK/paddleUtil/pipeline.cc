// Copyright (c) 2021 PaddlePaddle Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include "pipeline.h" // NOLINT
#include "timer.h"    // NOLINT
#include <algorithm>  // NOLINT
#include <cmath>      // NOLINT
#include <iostream>   // NOLINT
#include <map>        // NOLINT

namespace {

// 行级合并前的中间 OCR 单元。
// 每个 item 对应一个检测框及其识别结果。
struct OCRItem {
    std::string text;
    float score;
    std::vector<std::vector<int>> box;
    float min_x;
    float max_x;
    float min_y;
    float max_y;
    float center_x;
    float center_y;
    float height;
};

static bool IsValidBox(const std::vector<std::vector<int>> &box) {
    if (box.size() < 4) {
        return false;
    }
    for (const auto &point : box) {
        if (point.size() < 2) {
            return false;
        }
    }
    return true;
}

static bool BuildOCRItem(const std::string &text, float score,
                         const std::vector<std::vector<int>> &box,
                         OCRItem *item) {
    if (item == nullptr || !IsValidBox(box)) {
        return false;
    }
    OCRItem built_item;
    built_item.text = text;
    built_item.score = std::isfinite(score) ? score : 0.0f;
    built_item.box = box;
    built_item.min_x = static_cast<float>(box[0][0]);
    built_item.max_x = static_cast<float>(box[0][0]);
    built_item.min_y = static_cast<float>(box[0][1]);
    built_item.max_y = static_cast<float>(box[0][1]);

    for (size_t i = 1; i < box.size(); ++i) {
        built_item.min_x = std::min(built_item.min_x, static_cast<float>(box[i][0]));
        built_item.max_x = std::max(built_item.max_x, static_cast<float>(box[i][0]));
        built_item.min_y = std::min(built_item.min_y, static_cast<float>(box[i][1]));
        built_item.max_y = std::max(built_item.max_y, static_cast<float>(box[i][1]));
    }
    built_item.center_x = (built_item.min_x + built_item.max_x) * 0.5f;
    built_item.center_y = (built_item.min_y + built_item.max_y) * 0.5f;
    built_item.height = std::max(1.0f, built_item.max_y - built_item.min_y);
    if (!std::isfinite(built_item.center_x) || !std::isfinite(built_item.center_y) ||
        !std::isfinite(built_item.height)) {
        return false;
    }
    *item = std::move(built_item);
    return true;
}

static bool IsValidOCRItem(const OCRItem &item) {
    return IsValidBox(item.box) &&
           std::isfinite(item.score) &&
           std::isfinite(item.min_x) &&
           std::isfinite(item.max_x) &&
           std::isfinite(item.min_y) &&
           std::isfinite(item.max_y) &&
           std::isfinite(item.center_x) &&
           std::isfinite(item.center_y) &&
           std::isfinite(item.height) &&
           item.height > 0.0f &&
           item.min_x <= item.max_x &&
           item.min_y <= item.max_y;
}

static std::vector<std::vector<int>> BuildAxisAlignedBox(float min_x, float min_y,
                                                         float max_x, float max_y) {
    int left = static_cast<int>(std::round(min_x));
    int top = static_cast<int>(std::round(min_y));
    int right = static_cast<int>(std::round(max_x));
    int bottom = static_cast<int>(std::round(max_y));
    return {{left, top}, {right, top}, {right, bottom}, {left, bottom}};
}

static void MergeItemsByLine(const std::vector<OCRItem> &items,
                             std::vector<std::string> &merged_texts,
                             std::vector<float> &merged_scores,
                             std::vector<std::vector<std::vector<int>>> *merged_boxes) {
    merged_texts.clear();
    merged_scores.clear();
    if (merged_boxes != nullptr) {
        merged_boxes->clear();
    }
    if (items.empty()) {
        return;
    }

    // 1) 先按 Y 再按 X 进行稳定排序，提升分行聚类的一致性。
    std::vector<OCRItem> sorted_items;
    sorted_items.reserve(items.size());
    for (const auto &item : items) {
        if (IsValidOCRItem(item)) {
            sorted_items.push_back(item);
        }
    }
    if (sorted_items.empty()) {
        return;
    }
    std::stable_sort(sorted_items.begin(), sorted_items.end(), [](const OCRItem &a, const OCRItem &b) {
        if (a.center_y != b.center_y) {
            return a.center_y < b.center_y;
        }
        if (a.center_x != b.center_x) {
            return a.center_x < b.center_x;
        }
        if (a.text != b.text) {
            return a.text < b.text;
        }
        if (a.score != b.score) {
            return a.score < b.score;
        }
        return a.box < b.box;
    });

    std::vector<std::vector<OCRItem>> lines;
    for (const auto &item : sorted_items) {
        bool assigned = false;
        for (auto &line : lines) {
            float line_center_y = 0.0f;
            float line_height = 0.0f;
            for (const auto &line_item : line) {
                line_center_y += line_item.center_y;
                line_height += line_item.height;
            }
            line_center_y /= static_cast<float>(line.size());
            line_height /= static_cast<float>(line.size());

            // 2) 判断当前 item 是否属于已有行：
            //    阈值随文本高度自适应，并设置一个最小常量下限。
            float y_diff = std::fabs(item.center_y - line_center_y);
            float y_threshold = std::max(6.0f, std::max(item.height, line_height) * 0.55f);
            if (y_diff <= y_threshold) {
                line.push_back(item);
                assigned = true;
                break;
            }
        }
        if (!assigned) {
            lines.push_back({item});
        }
    }

    lines.erase(std::remove_if(lines.begin(), lines.end(),
                               [](const std::vector<OCRItem> &line) {
                                   return line.empty();
                               }),
                lines.end());
    if (lines.empty()) {
        return;
    }

    std::stable_sort(lines.begin(), lines.end(),
              [](const std::vector<OCRItem> &a, const std::vector<OCRItem> &b) {
                  if (a.empty() || b.empty()) {
                      return a.size() < b.size();
                  }
                  float ay = 0.0f;
                  float by = 0.0f;
                  for (const auto &item : a) ay += item.center_y;
                  for (const auto &item : b) by += item.center_y;
                  ay /= static_cast<float>(a.size());
                  by /= static_cast<float>(b.size());
                  if (ay != by) {
                      return ay < by;
                  }
                  if (a.front().center_x != b.front().center_x) {
                      return a.front().center_x < b.front().center_x;
                  }
                  return a.size() < b.size();
              });

    for (auto &line : lines) {
        // 3) 同一行内按从左到右顺序合并文本。
        std::stable_sort(line.begin(), line.end(), [](const OCRItem &a, const OCRItem &b) {
            if (a.center_x != b.center_x) {
                return a.center_x < b.center_x;
            }
            if (a.center_y != b.center_y) {
                return a.center_y < b.center_y;
            }
            if (a.text != b.text) {
                return a.text < b.text;
            }
            if (a.score != b.score) {
                return a.score < b.score;
            }
            return a.box < b.box;
        });

        std::string merged_text;
        float score_weighted_sum = 0.0f;
        float score_weight_sum = 0.0f;
        float line_min_x = line[0].min_x;
        float line_max_x = line[0].max_x;
        float line_min_y = line[0].min_y;
        float line_max_y = line[0].max_y;

        for (const auto &item : line) {
            merged_text += item.text;
            // 按文本长度加权，较长 token 对行级置信度贡献更大。
            float weight = std::max(1.0f, static_cast<float>(item.text.size()));
            score_weighted_sum += item.score * weight;
            score_weight_sum += weight;
            line_min_x = std::min(line_min_x, item.min_x);
            line_max_x = std::max(line_max_x, item.max_x);
            line_min_y = std::min(line_min_y, item.min_y);
            line_max_y = std::max(line_max_y, item.max_y);
        }

        if (!merged_text.empty()) {
            merged_texts.push_back(merged_text);
            merged_scores.push_back(score_weight_sum > 0.0f ? score_weighted_sum / score_weight_sum : 0.0f);
            if (merged_boxes != nullptr) {
                // 输出行级 box 使用轴对齐外接矩形，兼容 ObjC 侧处理。
                merged_boxes->push_back(
                    BuildAxisAlignedBox(line_min_x, line_min_y, line_max_x, line_max_y));
            }
        }
    }
}

} // namespace

cv::Mat GetRotateCropImage(const cv::Mat &srcimage,
                           std::vector<std::vector<int>> box) {
    if (srcimage.empty() || !IsValidBox(box)) {
        return cv::Mat();
    }
    std::vector<std::vector<int>> points = box;
    
    int x_collect[4] = {box[0][0], box[1][0], box[2][0], box[3][0]};
    int y_collect[4] = {box[0][1], box[1][1], box[2][1], box[3][1]};
    int left = std::max(0, int(*std::min_element(x_collect, x_collect + 4)));   // NOLINT
    int right = std::min(srcimage.cols, int(*std::max_element(x_collect, x_collect + 4)));  // NOLINT
    int top = std::max(0, int(*std::min_element(y_collect, y_collect + 4)));    // NOLINT
    int bottom = std::min(srcimage.rows, int(*std::max_element(y_collect, y_collect + 4))); // NOLINT
    if (right <= left || bottom <= top) {
        return cv::Mat();
    }
    
    cv::Mat img_crop;
    srcimage(cv::Rect(left, top, right - left, bottom - top)).copyTo(img_crop);
    
    for (int i = 0; i < points.size(); i++) {
        points[i][0] -= left;
        points[i][1] -= top;
    }
    
    int img_crop_width =
    static_cast<int>(sqrt(pow(points[0][0] - points[1][0], 2) +
                          pow(points[0][1] - points[1][1], 2)));
    int img_crop_height =
    static_cast<int>(sqrt(pow(points[0][0] - points[3][0], 2) +
                          pow(points[0][1] - points[3][1], 2)));
    if (img_crop_width <= 0 || img_crop_height <= 0) {
        return cv::Mat();
    }
    
    cv::Point2f pts_std[4];
    pts_std[0] = cv::Point2f(0., 0.);
    pts_std[1] = cv::Point2f(img_crop_width, 0.);
    pts_std[2] = cv::Point2f(img_crop_width, img_crop_height);
    pts_std[3] = cv::Point2f(0.f, img_crop_height);
    
    cv::Point2f pointsf[4];
    pointsf[0] = cv::Point2f(points[0][0], points[0][1]);
    pointsf[1] = cv::Point2f(points[1][0], points[1][1]);
    pointsf[2] = cv::Point2f(points[2][0], points[2][1]);
    pointsf[3] = cv::Point2f(points[3][0], points[3][1]);
    
    cv::Mat M = cv::getPerspectiveTransform(pointsf, pts_std);
    
    cv::Mat dst_img;
    cv::warpPerspective(img_crop, dst_img, M,
                        cv::Size(img_crop_width, img_crop_height),
                        cv::BORDER_REPLICATE);
    
    const float ratio = 1.5;
    if (static_cast<float>(dst_img.rows) >=
        static_cast<float>(dst_img.cols) * ratio) {
        cv::Mat srcCopy = cv::Mat(dst_img.rows, dst_img.cols, dst_img.depth());
        cv::transpose(dst_img, srcCopy);
        cv::flip(srcCopy, srcCopy, 0);
        return srcCopy;
    } else {
        return dst_img;
    }
}

std::vector<std::string> ReadDict(std::string path) {
    std::ifstream in(path);
    std::string filename;
    std::string line;
    std::vector<std::string> m_vec;
    if (in) {
        while (getline(in, line)) {
            m_vec.push_back(line);
        }
    } else {
        std::cout << "no such file" << std::endl;
    }
    return m_vec;
}

std::vector<std::string> split(const std::string &str,
                               const std::string &delim) {
    std::vector<std::string> res;
    if (str.empty() || delim.empty()) {
        return res;
    }

    size_t start = 0;
    while (start < str.size()) {
        size_t pos = str.find(delim, start);
        if (pos == std::string::npos) {
            std::string token = str.substr(start);
            if (!token.empty()) {
                res.push_back(token);
            }
            break;
        }

        if (pos > start) {
            res.push_back(str.substr(start, pos - start));
        }
        start = pos + delim.size();
    }

    return res;
}

std::map<std::string, double> LoadConfigTxt(std::string config_path) {
    auto config = ReadDict(config_path);
    
    std::map<std::string, double> dict;
    for (size_t i = 0; i < config.size(); i++) {
        std::vector<std::string> res = split(config[i], " ");
        if (res.size() < 2 || res[0].empty()) {
            continue;
        }
        dict[res[0]] = stod(res[1]);
    }
    return dict;
}

cv::Mat Visualization(cv::Mat srcimg,
                      std::vector<std::vector<std::vector<int>>> boxes,
                      std::string output_image_path) {
    cv::Point rook_points[boxes.size()][4];
    for (int n = 0; n < boxes.size(); n++) {
        for (int m = 0; m < boxes[0].size(); m++) {
            rook_points[n][m] = cv::Point(static_cast<int>(boxes[n][m][0]),
                                          static_cast<int>(boxes[n][m][1]));
        }
    }
    cv::Mat img_vis;
    srcimg.copyTo(img_vis);
    for (int n = 0; n < boxes.size(); n++) {
        const cv::Point *ppt[1] = {rook_points[n]};
        int npt[] = {4};
        cv::polylines(img_vis, ppt, npt, 1, 1, CV_RGB(0, 255, 0), 2, 8, 0);
    }
    
    cv::imwrite(output_image_path, img_vis);
//    std::cout << "The detection visualized image saved in "
//    << output_image_path.c_str() << std::endl;
    return img_vis;
}

void Pipeline::SetUseDirectionClassify(bool enabled) {
    use_direction_classify_override_ = enabled ? 1 : 0;
}


Pipeline::Pipeline(const std::string &detModelDir,
                   const std::string &clsModelDir,
                   const std::string &recModelDir,
                   const std::string &cPUPowerMode, const int cPUThreadNum,
                   const std::string &config_path,
                   const std::string &dict_path) {
    clsPredictor_.reset(
                        new ClsPredictor(clsModelDir, cPUThreadNum, cPUPowerMode));
    detPredictor_.reset(
                        new DetPredictor(detModelDir, cPUThreadNum, cPUPowerMode));
    recPredictor_.reset(
                        new RecPredictor(recModelDir, cPUThreadNum, cPUPowerMode));
    Config_ = LoadConfigTxt(config_path);
    charactor_dict_ = ReadDict(dict_path);
    charactor_dict_.insert(charactor_dict_.begin(), "#"); // NOLINT
    charactor_dict_.push_back(" ");
    use_direction_classify_override_ = -1;
}

cv::Mat Pipeline::Process(const cv::Mat &img, std::string output_img_path,
                          std::vector<std::string> &res_txt,
                          std::vector<std::vector<std::vector<int>>> *res_boxes,
                          bool enable_visualization) {
    //  Timer tic;
    //  tic.start();
    int use_direction_classify = use_direction_classify_override_ >= 0 ? use_direction_classify_override_ : int(Config_["use_direction_classify"]); // NOLINT
    // det predict
    auto boxes =
    detPredictor_->Predict(img, Config_, nullptr, nullptr, nullptr);
    
    cv::Mat crop_img;
    
    // 行级合并前的原始识别结果（每个检测框一个）。
    std::vector<OCRItem> recognized_items;
    recognized_items.reserve(boxes.size());
    if (res_boxes != nullptr) {
        res_boxes->clear();
    }
    
    for (auto it = boxes.rbegin(); it != boxes.rend(); ++it) {
        const auto &box = *it;
        if (!IsValidBox(box)) {
            continue;
        }
        crop_img = GetRotateCropImage(img, box);
        if (crop_img.empty()) {
            continue;
        }
        if (use_direction_classify >= 1) {
            crop_img =
            clsPredictor_->Predict(crop_img, nullptr, nullptr, nullptr, 0.9);
        }
        if (crop_img.empty()) {
            continue;
        }
        auto res = recPredictor_->Predict(crop_img, nullptr, nullptr, nullptr,
                                          charactor_dict_);
        OCRItem item;
        if (BuildOCRItem(res.first, res.second, box, &item)) {
            recognized_items.push_back(std::move(item));
        }
    }
    // tic.end();
    // *processTime = tic.get_average_ms();
    // std::cout << "pipeline predict costs" <<  *processTime;
    cv::Mat img_vis;
    if (enable_visualization) {
        img_vis = Visualization(img, boxes, output_img_path);
    }
    // 在 C++ 侧合并同一行碎片，并保持输出协议不变：
    // res_txt = [text0, score0, text1, score1, ...]
    std::vector<std::string> merged_text;
    std::vector<float> merged_score;
    MergeItemsByLine(recognized_items, merged_text, merged_score, res_boxes);

    // 输出按“行”合并后的识别文本与置信度。
    res_txt.clear();
    res_txt.resize(merged_text.size() * 2);
    for (int i = 0; i < merged_text.size(); i++) {
        //    std::cout << i << "\t" << rec_text[i] << "\t" << rec_text_score[i]
        //              << std::endl;
        std::ostringstream ss;
        ss << merged_score[i];
        res_txt[2 * i] = merged_text[i];
        res_txt[2 * i + 1] = ss.str();
    }

    return img_vis;
}

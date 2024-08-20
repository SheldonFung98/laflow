import 'package:camera/camera.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'dart:typed_data';
import 'dart:math';

class ImageProcessing {
  cv.Mat? image;
  cv.Mat? warped_img;
  cv.Mat? inspectionArea;
  List<double>? barValue;
  double? result;
  cv.CLAHE clahe = cv.CLAHE(1.0, (8, 8));

  Uint8List convertToBytes(cv.Mat? img) {
    return cv.imencode(".png", img!).$2;
  }

  Future<void> loadXFile(XFile file) async {
    cv.Mat img = cv.imread(file.path);
    loadMat(img);
  }

  Future<void> loadMat(cv.Mat img) async {
    if (img.rows > img.cols) {
      // rotate image 90 degrees
      img = cv.rotate(img, cv.ROTATE_90_CLOCKWISE);
    }

    int h = img.rows;
    int w = img.cols;

    // int w_min, w_max, h_min, h_max;
    double xCrop = 0.10;
    double yCrop = 0.25;
    int x = (w * xCrop).toInt();
    int weight = (w * (1 - 2 * xCrop)).toInt();
    int y = (h * yCrop).toInt();
    int height = (h * (1 - 2 * yCrop)).toInt();

    // crop image
    img = img.region(cv.Rect(x, y, weight, height));

    image = img;
  }

  Future<bool> alignSample() async {
    bool valid = false;
    cv.Mat img = image!.clone();

    // Convert to grayscale
    cv.Mat gray = cv.cvtColor(img, cv.COLOR_BGR2GRAY);

    // Apply Gaussian Blur
    // cv.Mat blurred = cv.gaussianBlur(gray, (3, 3), 0);

    cv.Mat enhance = clahe.apply(gray);

    // Apply Canny Edge Detection
    cv.Mat edges = cv.canny(enhance, 50, 200);

    // Apply morphological operations
    cv.Mat morphKernel = cv.getStructuringElement(cv.MORPH_RECT, (3, 3));
    edges = cv.morphologyEx(edges, cv.MORPH_CLOSE, morphKernel, iterations: 6);

    // Find contours
    cv.Contours contours;
    (contours, _) =
        cv.findContours(edges, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE);
    if (contours.isEmpty) {
      return false;
    }
    // draw contours
    cv.drawContours(image!, contours, -1, cv.Scalar(0, 255, 0), thickness: 3);

    // Sort contours by area
    List<cv.VecPoint> contoursList = contours.toList();
    contoursList
        .sort((a, b) => cv.contourArea(b).compareTo(cv.contourArea(a)));

    // Find the largest rectangle
    cv.VecPoint approx = cv.VecPoint();
    for (var contour in contoursList) {
      if (contour.length < 50) {
        continue;
      }

      double epsilon =
          0.02 * cv.arcLength(cv.VecPoint.fromList(contour.toList()), true);
      approx = cv.approxPolyDP(
          cv.VecPoint.fromList(contour.toList()), epsilon, true);

      if (approx.length == 4) {
        break;
      }
    }

    valid = approx.isNotEmpty;

    // cv.drawContours(image!, approx.toVecVecPoint, -1, cv.Scalar(255, 255, 0),
    //     thickness: 3);

    // Draw contours
    cv.Mat roi_ = img.clone();
    cv.drawContours(roi_, approx.toVecVecPoint, -1, cv.Scalar(0, 255, 0),
        thickness: 3);

    // Find corners
    List<cv.Point> approxPoints = approx.toList();
    List<cv.Point2f> corner = List.filled(4, cv.Point2f(0, 0));

    // Top-left corner has the smallest sum
    cv.Point topleft =
        approxPoints.reduce((a, b) => (a.x + a.y < b.x + b.y) ? a : b);
    corner[0] = cv.Point2f(topleft.x.toDouble(), topleft.y.toDouble());

    // Bottom-right corner has the largest sum
    cv.Point bottomright =
        approxPoints.reduce((a, b) => (a.x + a.y > b.x + b.y) ? a : b);
    corner[2] = cv.Point2f(bottomright.x.toDouble(), bottomright.y.toDouble());

    // Top-right corner has the smallest difference
    cv.Point topright =
        approxPoints.reduce((a, b) => (a.y - a.x < b.y - b.x) ? a : b);
    corner[1] = cv.Point2f(topright.x.toDouble(), topright.y.toDouble());

    // Bottom-left corner has the largest difference
    cv.Point bottomleft =
        approxPoints.reduce((a, b) => (a.y - a.x > b.y - b.x) ? a : b);
    corner[3] = cv.Point2f(bottomleft.x.toDouble(), bottomleft.y.toDouble());

    // draw corner on image
    cv.circle(image!, cv.Point(corner[0].x.toInt(), corner[0].y.toInt()), 10,
        cv.Scalar(50, 50, 50),
        thickness: -1);
    cv.circle(image!, cv.Point(corner[1].x.toInt(), corner[1].y.toInt()), 10,
        cv.Scalar(100, 100, 100),
        thickness: -1);
    cv.circle(image!, cv.Point(corner[2].x.toInt(), corner[2].y.toInt()), 10,
        cv.Scalar(150, 150, 150),
        thickness: -1);
    cv.circle(image!, cv.Point(corner[3].x.toInt(), corner[3].y.toInt()), 10,
        cv.Scalar(250, 250, 250),
        thickness: -1);

    // draw lines
    cv.line(
        image!,
        cv.Point(corner[0].x.toInt(), corner[0].y.toInt()),
        cv.Point(corner[1].x.toInt(), corner[1].y.toInt()),
        cv.Scalar(0, 0, 255));
    cv.line(
        image!,
        cv.Point(corner[1].x.toInt(), corner[1].y.toInt()),
        cv.Point(corner[2].x.toInt(), corner[2].y.toInt()),
        cv.Scalar(0, 0, 255));
    cv.line(
        image!,
        cv.Point(corner[2].x.toInt(), corner[2].y.toInt()),
        cv.Point(corner[3].x.toInt(), corner[3].y.toInt()),
        cv.Scalar(0, 0, 255));
    cv.line(
        image!,
        cv.Point(corner[3].x.toInt(), corner[3].y.toInt()),
        cv.Point(corner[0].x.toInt(), corner[0].y.toInt()),
        cv.Scalar(0, 0, 255));

    // Perspective transform
    int width = 1300;
    int height = 400;
    List<cv.Point2f> dst = [
      cv.Point2f(0, 0),
      cv.Point2f(width - 1, 0),
      cv.Point2f(width - 1, height - 1),
      cv.Point2f(0, height - 1)
    ];

    cv.VecPoint2f cornerMat = cv.VecPoint2f.fromList(corner);
    cv.VecPoint2f dstMat = cv.VecPoint2f.fromList(dst);

    cv.Mat matrix = cv.getPerspectiveTransform2f(cornerMat, dstMat);

    warped_img = cv.warpPerspective(img, matrix, (width, height));
    return valid;
  }

  Future<List<cv.Rect>> findVerticalStripes() async {
    // Convert to grayscale
    cv.Mat gray = cv.cvtColor(warped_img!.clone(), cv.COLOR_RGB2GRAY);

    // Apply CLAHE
    gray = clahe.apply(gray);

    // Apply thresholding
    cv.Mat binary;
    (_, binary) =
        cv.threshold(gray, 0, 255, cv.THRESH_BINARY_INV + cv.THRESH_OTSU);

    // Apply morphological operations
    cv.Mat morphKernel = cv.getStructuringElement(cv.MORPH_RECT, (5, 5));
    binary = cv.morphologyEx(binary, cv.MORPH_OPEN, morphKernel, iterations: 3);

    // Detect vertical lines
    cv.Mat verticalKernel = cv.getStructuringElement(cv.MORPH_RECT, (1, 5));
    cv.Mat verticalLines =
        cv.morphologyEx(binary, cv.MORPH_OPEN, verticalKernel, iterations: 5);

    // Find contours
    // List<cv.MatOfPoint> contours = await cv.findContours(verticalLines, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE);

    // Find contours
    cv.Contours contours;
    (contours, _) = cv.findContours(
        verticalLines, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE);

    // Sort contours by area
    contours
        .toList()
        .sort((a, b) => cv.contourArea(b).compareTo(cv.contourArea(a)));

    List<cv.Rect> rects = [];
    for (var contour in contours) {
      cv.Rect rect = cv.boundingRect(contour);
      rects.add(rect);
      // cv.rectangle(warped_img!, rect, cv.Scalar(0, 255, 0), thickness: 3);
      // cv.circle(
      //     warped_img!,
      //     cv.Point(rect.x + rect.width ~/ 2, rect.y + rect.height ~/ 2),
      //     5,
      //     cv.Scalar(255, 0, 0),
      //     thickness: -1);
    }

    return rects;
  }

  cv.Rect getReference(List<cv.Rect> rects) {
    List<cv.Point> centers = rects
        .map((rect) =>
            cv.Point(rect.x + rect.width ~/ 2, rect.y + rect.height ~/ 2))
        .toList();
    int leftMostX =
        centers.map((center) => center.x).reduce((a, b) => a < b ? a : b);
    bool isLeft = leftMostX < warped_img!.cols ~/ 2;
    rects.sort((a, b) => isLeft ? a.x.compareTo(b.x) : b.x.compareTo(a.x));
    return rects.first;
  }

  cv.Rect getInspectionArea(cv.Rect reference, bool isLeft,
      {double factor = 2.15, int xPadding = 20, int yPadding = 10}) {
    int x = reference.x;
    int y = reference.y;
    int w = reference.width;
    int h = reference.height;
    int windowW = (factor * h).toInt();
    if (isLeft) {
      return cv.Rect(x - xPadding, y + yPadding, w + windowW + 2 * xPadding,
          h - 2 * yPadding);
    } else {
      return cv.Rect(x - windowW - xPadding, y + yPadding,
          w + windowW + 2 * xPadding, h - 2 * yPadding);
    }
  }

  // List<double> calculateRedCurve(cv.Mat inspectionRoi) {
  //   List<double> redCurve = [];
  //   for (int i = 0; i < inspectionRoi.cols; i++) {
  //     double meanValue = 0;
  //     for (int j = 0; j < inspectionRoi.rows; j++) {
  //       meanValue += inspectionRoi.at(j, i)[0];
  //     }
  //     meanValue /= inspectionRoi.rows;
  //     redCurve.add(255 - meanValue);
  //   }
  //   return redCurve;
  // }

  List<double> calculateRedCurve(cv.Mat inspectionRoi) {
    List<double> redCurve = [];
    for (int i = 0; i < inspectionRoi.cols; i++) {
      List<int> values = [];
      for (int j = 0; j < inspectionRoi.rows; j++) {
        var pixel = inspectionRoi.at<cv.Vec3b>(j, i);
        values.add(pixel.val1);
      }
      double meanValue = values.reduce((a, b) => a + b) / values.length;

      redCurve.add(255.0 - meanValue);
    }
    return redCurve;
  }

  List<double> smoothCurve(List<double> redCurve) {
    // Apply Gaussian blur (approximated)
    List<double> smoothed = List.from(redCurve);
    for (int i = 1; i < redCurve.length - 1; i++) {
      smoothed[i] = (redCurve[i - 1] + redCurve[i] + redCurve[i + 1]) / 3;
    }
    return smoothed;
  }

  List<double> calculateBarValue(List<double> smoothed, bool isLeft) {
    smoothed = smoothed.sublist(0, smoothed.length - (smoothed.length % 4));
    const int barNum = 4;
    int length = smoothed.length ~/ barNum;
    List<List<double>> reshaped = [];
    for (int i = 0; i < barNum; i++) {
      reshaped.add(smoothed.sublist(i * length, (i + 1) * length));
    }
    if (!isLeft) {
      reshaped = reshaped.reversed.toList();
    }
    List<double> barValue = List.generate(barNum, (index) {
      return reshaped[index].reduce(max);
    });

    double minRef = List.generate(barNum, (i) {
          return reshaped[i].reduce(min);
        }).reduce((a, b) => a + b) /
        barNum;

    barValue = barValue.map((value) => value - minRef).toList();
    double firstValue = barValue[0];
    barValue = barValue.map((value) => value / firstValue * 100).toList();
    return barValue;
  }

  double lateralFlowRes(List<double> barValue) {
    double value;
    if (barValue[1] > 50) {
      value = barValue[1];
    } else if (barValue[2] > 10) {
      value = barValue[2];
    } else {
      value = barValue[3];
    }
    value = min(value, 100);
    value = max(value, 0);
    return value;
  }

  Future<bool> process() async {
    if (await alignSample()) {
      List<cv.Rect> rects = await findVerticalStripes();

      if (rects.isNotEmpty) {
        cv.Rect reference = getReference(rects);
        bool isLeft = reference.x < warped_img!.cols ~/ 2;
        // rotate image 180 degrees if it is right

        cv.Rect inspectionRect = getInspectionArea(reference, isLeft);

        inspectionArea = warped_img!.region(inspectionRect);

        List<double> redCurve = calculateRedCurve(inspectionArea!);
        // print("Red Curve: $redCurve");
        List<double> smoothed = smoothCurve(redCurve);
        barValue = calculateBarValue(smoothed, isLeft);
        result = lateralFlowRes(barValue!);

        // draw
        cv.rectangle(warped_img!, reference, cv.Scalar(0, 0, 255),
            thickness: 3);
        cv.rectangle(warped_img!, inspectionRect, cv.Scalar(0, 255, 0),
            thickness: 3);
        if (!isLeft) {
          inspectionArea = cv.rotate(inspectionArea!, cv.ROTATE_180);
        }
        return true;
      }
    }
    return false;
  }
}

class ApiResponse<T> {
  final int code;
  final bool success;
  final String message;
  final List<T> data;

  ApiResponse({
    required this.code,
    required this.success,
    required this.message,
    required this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    var dataList = json['data'] as List<dynamic>? ?? [];

    return ApiResponse<T>(
      code: json['code'],
      success: json['success'],
      message: json['message'],
      data: dataList.map((item) => fromJsonT(item)).toList(),
    );
  }
}

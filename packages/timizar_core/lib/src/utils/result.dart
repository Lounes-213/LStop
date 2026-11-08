/// Functional Result pattern for type-safe error handling without throwing unchecked exceptions
sealed class Result<T, E> {
  const Result();

  bool get isSuccess => this is Success<T, E>;
  bool get isFailure => this is Failure<T, E>;

  T? get dataOrNull => switch (this) {
    Success(:final data) => data,
    Failure() => null,
  };

  E? get errorOrNull => switch (this) {
    Success() => null,
    Failure(:final error) => error,
  };

  R when<R>({
    required R Function(T data) success,
    required R Function(E error) failure,
  }) {
    return switch (this) {
      Success(:final data) => success(data),
      Failure(:final error) => failure(error),
    };
  }

  Result<R, E> map<R>(R Function(T data) transform) {
    return switch (this) {
      Success(:final data) => Success(transform(data)),
      Failure(:final error) => Failure(error),
    };
  }
}

final class Success<T, E> extends Result<T, E> {
  final T data;
  const Success(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Success<T, E> && other.data == data;

  @override
  int get hashCode => data.hashCode;
}

final class Failure<T, E> extends Result<T, E> {
  final E error;
  const Failure(this.error);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Failure<T, E> && other.error == error;

  @override
  int get hashCode => error.hashCode;
}

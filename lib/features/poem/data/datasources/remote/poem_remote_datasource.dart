import 'package:dio/dio.dart';
import 'package:poem_studio/features/poem/data/models/poem_edit_dto.dart';
import 'package:retrofit/retrofit.dart';

part 'poem_remote_datasource.g.dart';

@RestApi()
abstract class PoemRemoteDataSource {
  factory PoemRemoteDataSource(Dio dio, {String baseUrl}) =
      _PoemRemoteDataSource;

  @GET('/api/v1/poems/edits')
  Future<PoemEditsResponseDto> getEdits();

  @PUT('/api/v1/poems/edits/{id}')
  Future<PoemEditDto> putEdit(
    @Path('id') String id,
    @Body() PoemEditBodyDto body,
  );
}

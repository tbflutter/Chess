import 'duringGame.dart';

bool canPieceMove(Piece piece, Position departure, Position destination) {
  return destination.alphanumericPosition[0] == "a";
}

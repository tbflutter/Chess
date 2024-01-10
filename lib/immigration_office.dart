import 'package:flutter/material.dart';
import 'duringGame.dart';
import 'chess_board.dart';

class BoardCommunication {
  late Board frontBoard;
  late ChessBoard backBoard;

  BoardCommunication.init(this.frontBoard, this.backBoard);

  void sendMovingRequest(Piece piece, Position departure, Position destination) {
    List<int> intDeparture = Translate.frontPosition_to_backPosition(departure);
    List<int> intDestination = Translate.frontPosition_to_backPosition(destination);

    print(departure.alphanumeric);
    print(intDeparture);
    print(backBoard.boardState[intDeparture[0]][intDeparture[1]]);
    print(destination.alphanumeric);
    print(intDestination);
    print(backBoard.boardState[intDestination[0]][intDestination[1]]);
    backBoard.turnMove(intDeparture, intDestination);
    print("");
  }

  void syncBoard(MoveType moveType) {
    print(moveType);
    List<List<Piece?>> transcribedBoard = List.generate(ChessBoard.boardSize[1], (i) =>
        List.generate(ChessBoard.boardSize[0], (j) => Translate.backPiece_to_frontPiece(backBoard.boardState[i][j])));

    for (int i = 0; i < transcribedBoard.length; i++) {
      for (int j = 0; j < transcribedBoard.length; j++) {
        Position position = Translate.backPosition_to_frontPosition([i, j]);
        Piece? piece = transcribedBoard[i][j];
        frontBoard.setPiece(position, piece);
      }
    }
  }
}

class Translate {
  static List<int> frontPosition_to_backPosition(Position position) {
    int file = position.alphanumeric.codeUnitAt(0) - 97;
    int rank = 7 - (int.parse(position.alphanumeric[1]) - 1);

    return [rank, file];
  }
  
  static Position backPosition_to_frontPosition(List<int> position) {
    String file = String.fromCharCode(position[1] + 97);
    String rank = String.fromCharCode((7 - position[0]) + 49);

    return Position(file + rank);
  }

  static Pieces frontPiece_to_backPiece(Piece? frontPiece) {
    if (frontPiece is Pawn) {
      return (frontPiece.color == Colors.white) ? Pieces.wP : Pieces.bP;
    } else if (frontPiece is Bishop) {
      return (frontPiece.color == Colors.white) ? Pieces.wB : Pieces.bB;
    } else if (frontPiece is Knight) {
      return (frontPiece.color == Colors.white) ? Pieces.wN : Pieces.bN;
    } else if (frontPiece is Rook) {
      return (frontPiece.color == Colors.white) ? Pieces.wR : Pieces.bR;
    } else if (frontPiece is Queen) {
      return (frontPiece.color == Colors.white) ? Pieces.wQ : Pieces.bQ;
    } else if (frontPiece is King) {
      return (frontPiece.color == Colors.white) ? Pieces.wK : Pieces.bK;
    } else {
      return Pieces.nX;
    }
  }

  static Piece? backPiece_to_frontPiece(Pieces backPiece) {
    switch (backPiece) {
      case Pieces.wP:
        return Pawn(Colors.white);
      case Pieces.wN:
        return Knight(Colors.white);
      case Pieces.wB:
        return Bishop(Colors.white);
      case Pieces.wR:
        return Rook(Colors.white);
      case Pieces.wQ:
        return Queen(Colors.white);
      case Pieces.wK:
        return King(Colors.white);

      case Pieces.bP:
        return Pawn(Colors.black);
      case Pieces.bN:
        return Knight(Colors.black);
      case Pieces.bB:
        return Bishop(Colors.black);
      case Pieces.bR:
        return Rook(Colors.black);
      case Pieces.bQ:
        return Queen(Colors.black);
      case Pieces.bK:
        return King(Colors.black);

      case Pieces.nX:
        return null;
    }
  }

}


import 'package:flutter/material.dart';
import 'during_game.dart';
import 'chess_board.dart';

class BoardCommunication {
  late Board frontBoard;
  late ChessBoard backBoard;
  Type promotePiece = Queen;

  BoardCommunication.init(this.frontBoard, this.backBoard);

  void sendMovingRequest(Piece piece, Position departure, Position destination) {
    List<int> intDeparture = Translate.frontPosition_to_backPosition(departure);
    List<int> intDestination = Translate.frontPosition_to_backPosition(destination);

    Player? winPlayer = backBoard.turnMove(intDeparture, intDestination);
    if (winPlayer != null) {
      gameOver(Translate.backPlayer_to_frontPlayer(winPlayer));
    }
  }

  void syncBoard(MoveType moveType) {
    List<List<Piece?>> transcribedBoard = List.generate(ChessBoard.boardSize[1], (i) =>
        List.generate(ChessBoard.boardSize[0], (j) => Translate.backPiece_to_frontPiece(backBoard.boardState[i][j])));

    for (int i = 0; i < transcribedBoard.length; i++) {
      for (int j = 0; j < transcribedBoard[0].length; j++) {
        Position position = Translate.backPosition_to_frontPosition([i, j]);
        Piece? piece = transcribedBoard[j][i];
        frontBoard.setPiece(position, piece);
      }
    }

    syncTurnPlayer(Translate.backPlayer_to_frontPlayer(communicator.backBoard.lastPlayer));
  }

  PieceType getPromotePiece() { //TODO
    return Translate.frontPieceType_to_backPiecetype(promotePiece);
  }
}

class Translate {
  static List<int> frontPosition_to_backPosition(Position position) {
    int file = position.alphanumeric.codeUnitAt(0) - 97;
    int rank = 7 - (int.parse(position.alphanumeric[1]) - 1);

    return [file, rank];
  }
  
  static Position backPosition_to_frontPosition(List<int> position) {
    String file = String.fromCharCode(position[0] + 97);
    String rank = String.fromCharCode((7 - position[1]) + 49);

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

  static Color backPlayer_to_frontPlayer(Player player) {
    if (player == Player.w) {
      return Colors.white;
    } else if (player == Player.b) {
      return Colors.black;
    } else {
      return Colors.grey;
    }
  }

  static PieceType frontPieceType_to_backPiecetype(Type pieceType) {
    if (pieceType == Queen) {
      return PieceType.Q;
    } else if (pieceType == Rook) {
      return PieceType.R;
    } else if (pieceType == Knight) {
      return PieceType.N;
    } else if (pieceType == Bishop) {
      return PieceType.B;
    } else {
      throw "Unexpected piece type";
    }
  }
}


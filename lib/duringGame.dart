import 'package:flutter/material.dart';
import 'package:test11/immigration_office.dart';
import 'chess_board.dart';

class DuringGame extends StatefulWidget {
  const DuringGame({super.key});

  @override
  State<DuringGame> createState() => _DuringGameState();
}

Board board = Board();
ChessBoard _backBoard = ChessBoard();
Piece? selectedPiece;
BoardCommunication communicator = BoardCommunication.init(board, _backBoard);

class _DuringGameState extends State<DuringGame> {
  @override
  void initState() {
    board.init(setState);
    _backBoard.initBoard();
    communicator.syncBoard(MoveType.x);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PopScope(
        canPop: false,
        onPopInvoked: (value) {},
        child: Scaffold(
          body: board.build(context),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              print("d");
            },
          ),
        ),
      ),
    );
  }
}

class Board {
  late List<Cell> _rawCells;
  late dynamic setState;

  void init(setState) {
    this.setState = setState;

    _rawCells = List.generate(8 * 8, (index) {
      Color color = (index + index ~/ 8) % 2 == 0 ? Colors.white : Colors.black;

      return Cell(color, setState, Position._set_index(index));
    });

    setPiece(Position("a2"), Pawn(Colors.white));
  }

  Widget build(BuildContext context) {
    return Center(
      // <div> https://docs.flutter.dev/cookbook/lists/grid-lists#interactive-example
      child: Stack(
        children: [
          GridView.count(
            crossAxisCount: 8,
            // Generate 100 widgets that display their index in the List.
            children: List.generate(8 * 8, (index) {
              return board._rawCells[index].build(context);
            }),
          ),
        ],
      ),
      // </div> https://docs.flutter.dev/cookbook/lists/grid-lists#interactive-example
    );
  }

  Cell getCell(Position position) {
    return _rawCells[position._index];
  }

  Piece? getPiece(Position position) {
    return getCell(position).piece;
  }

  void setPiece(Position position, Piece? piece) {
    setState(() {
      getCell(position).piece = piece;
      piece?.position = position;
    });
  }
}

class Position {
  late String alphanumeric;
  late int _index;

  Position(this.alphanumeric) {
    _index = 0;

    switch (alphanumeric[0]) {
      case "a":
        _index += 0;
      case "b":
        _index += 1;
      case "c":
        _index += 2;
      case "d":
        _index += 3;
      case "e":
        _index += 4;
      case "f":
        _index += 5;
      case "g":
        _index += 6;
      case "h":
        _index += 7;
    }

    switch (alphanumeric[1]) {
      case "1":
        _index += 56;
      case "2":
        _index += 48;
      case "3":
        _index += 40;
      case "4":
        _index += 32;
      case "5":
        _index += 24;
      case "6":
        _index += 16;
      case "7":
        _index += 8;
      case "8":
        _index += 0;
    }
  }

  Position._set_index(this._index) {
    alphanumeric = "";

    switch (_index % 8) {
      case 0:
        alphanumeric += "a";
      case 1:
        alphanumeric += "b";
      case 2:
        alphanumeric += "c";
      case 3:
        alphanumeric += "d";
      case 4:
        alphanumeric += "e";
      case 5:
        alphanumeric += "f";
      case 6:
        alphanumeric += "g";
      case 7:
        alphanumeric += "h";
    }

    switch ((_index ~/ 8) * 8) {
      case 0:
        alphanumeric += "8";
      case 8:
        alphanumeric += "7";
      case 16:
        alphanumeric += "6";
      case 24:
        alphanumeric += "5";
      case 32:
        alphanumeric += "4";
      case 40:
        alphanumeric += "3";
      case 48:
        alphanumeric += "2";
      case 56:
        alphanumeric += "1";
    }
  }
}

class Piece {
  late String imageDirectory;
  late AssetImage targetImage;
  late Widget body;
  late Position position;
  late Color color;

  Widget setBody(Widget child) {
    body = GestureDetector(
      onTap: () {
        if (selectedPiece != null) {
          communicator.sendMovingRequest(
              selectedPiece!, selectedPiece!.position, this.position);
          selectedPiece = null;
        } else {
          selectedPiece = this;
        }
      },
      child: child,
    );

    return body;
  }

  Piece(this.color) {
    imageDirectory =
        color == Colors.white ? "assets/pieces/white" : "assets/pieces/black";
  }

/*
    if (canPieceMove(this, departure, destination)) {
      // Move
      board.setPiece(departure, null);
      board.setPiece(destination, this);
    } else {
      selectedPiece = null;
    }
    */
}

class Pawn extends Piece {
  Pawn(super.color) {
    AssetImage targetImage = AssetImage("${super.imageDirectory}/pawn.png");

    setBody(
      Image(image: targetImage),
    );
  }
}

class Bishop extends Piece {
  Bishop(super.imageDirectory) {
    AssetImage targetImage = AssetImage("$imageDirectory/bishop.png");

    setBody(
      Image(image: targetImage),
    );
  }
}

class Knight extends Piece {
  Knight(super.imageDirectory) {
    AssetImage targetImage = AssetImage("$imageDirectory/knight.png");

    setBody(
      Image(image: targetImage),
    );
  }
}

class Rook extends Piece {
  bool hasMoved = false;

  Rook(super.imageDirectory) {
    AssetImage targetImage = AssetImage("$imageDirectory/rook.png");

    setBody(
      Image(image: targetImage),
    );
  }
}

class Queen extends Piece {
  Queen(super.imageDirectory) {
    AssetImage targetImage = AssetImage("$imageDirectory/queen.png");

    setBody(
      Image(image: targetImage),
    );
  }
}

class King extends Piece {
  bool hasMoved = false;

  King(super.imageDirectory) {
    AssetImage targetImage = AssetImage("$imageDirectory/king.png");

    setBody(
      Image(image: targetImage),
    );
  }
}

class Cell {
  late Color color;
  late dynamic setState;
  late Position position;
  Piece? piece;

  Cell(this.color, this.setState, this.position);

  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Center(
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (selectedPiece != null) {
              communicator.sendMovingRequest(
                  selectedPiece!, selectedPiece!.position, this.position);
              selectedPiece = null;
            }
          });
        },
        child: Container(
          color: color,
          child: SizedBox(
            width: size.width * 0.15,
            height: size.width * 0.15,
            child: piece?.body,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class DuringGame extends StatefulWidget {
  const DuringGame({super.key});

  @override
  State<DuringGame> createState() => _DuringGameState();
}

Board board = Board();
Piece? selectedPiece;

class _DuringGameState extends State<DuringGame> {
  @override
  void initState() {
    board.init(setState);
  }

  @override
  Widget build(BuildContext context) {
    // board.init(setState);

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
  late List<Cell> rawCells;
  late dynamic setState;

  void init(setState) {
    this.setState = setState;

    rawCells = List.generate(8 * 8, (index) {
      Color color = (index + index ~/ 8) % 2 == 0 ? Colors.white : Colors.black;

      return Cell(color, setState, Position.index(index));
    });

    setPiece(Position.alphanumeric("a2"), Pawn(Colors.white));
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
              return board.rawCells[index].build(context);
            }),
          ),
        ],
      ),
      // </div> https://docs.flutter.dev/cookbook/lists/grid-lists#interactive-example
    );
  }

  Cell getCell(Position position) {
    return rawCells[position.indexPosition];
  }

  void setPiece(Position position, Piece? piece) {
    setState(() {
      rawCells[position.indexPosition].piece = piece;
      piece?.position = position;
    });
  }
}

class Position {
  late String alphanumericPosition;
  late int indexPosition;

  Position.alphanumeric(this.alphanumericPosition) {
    indexPosition = 0;

    switch (alphanumericPosition[0]) {
      case "a":
        indexPosition += 0;
      case "b":
        indexPosition += 1;
      case "c":
        indexPosition += 2;
      case "d":
        indexPosition += 3;
      case "e":
        indexPosition += 4;
      case "f":
        indexPosition += 5;
      case "g":
        indexPosition += 6;
      case "h":
        indexPosition += 7;
    }

    switch (alphanumericPosition[1]) {
      case "1":
        indexPosition += 0;
      case "2":
        indexPosition += 8;
      case "3":
        indexPosition += 16;
      case "4":
        indexPosition += 24;
      case "5":
        indexPosition += 32;
      case "6":
        indexPosition += 40;
      case "7":
        indexPosition += 48;
      case "8":
        indexPosition += 56;
    }
  }

  Position.index(this.indexPosition) {
    alphanumericPosition = "";

    switch (indexPosition % 8) {
      case 0:
        alphanumericPosition += "a";
      case 1:
        alphanumericPosition += "b";
      case 2:
        alphanumericPosition += "c";
      case 3:
        alphanumericPosition += "d";
      case 4:
        alphanumericPosition += "e";
      case 5:
        alphanumericPosition += "f";
      case 6:
        alphanumericPosition += "g";
      case 7:
        alphanumericPosition += "h";
    }

    switch ((indexPosition ~/ 8) * 8) {
      case 0:
        alphanumericPosition += "1";
      case 8:
        alphanumericPosition += "2";
      case 16:
        alphanumericPosition += "3";
      case 24:
        alphanumericPosition += "4";
      case 32:
        alphanumericPosition += "5";
      case 40:
        alphanumericPosition += "6";
      case 48:
        alphanumericPosition += "7";
      case 56:
        alphanumericPosition += "8";
    }
  }
}

class Pieces {}

class Piece {
  late String imageDirectory;
  late AssetImage targetImage;
  late Widget body;
  late Position position;

  Widget setBody(Widget child) {
    body = GestureDetector(
      onTap: () {
        selectedPiece = this;
      },
      child: child,
    );

    return body;
  }

  Piece(Color color) {
    imageDirectory =
        color == Colors.white ? "assets/pieces/white" : "assets/pieces/black";
  }

  void move(Position destination) {
    Position departure = position;

    // Validation
    if (true) {
      // Move
      board.setPiece(departure, null);
      board.setPiece(destination, this);
    } else {
      selectedPiece = null;
    }
  }
}

class Pawn extends Piece {
  Pawn(super.imageDirectory) {
    AssetImage targetImage = AssetImage("$imageDirectory/pawn.png");

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
            selectedPiece?.move(position);
            selectedPiece = null;
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

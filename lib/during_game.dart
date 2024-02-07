import 'package:flutter/material.dart';
import 'package:test11/immigration_office.dart';
import 'chess_board.dart';

class DuringGame extends StatefulWidget {
  const DuringGame({super.key});

  @override
  State<DuringGame> createState() => _DuringGameState();
}

Board board = Board();
Piece? selectedPiece;
Color turnPlayer = Colors.white;
ChessBoard _backBoard = ChessBoard();
BoardCommunication communicator = BoardCommunication.init(board, _backBoard);

void syncTurnPlayer(Color player) {
  turnPlayer = player;
}

late dynamic setState;

class _DuringGameState extends State<DuringGame> {
  @override
  void initState() {
    super.initState();
    setState = this.setState;
    board.init();
    _backBoard.initBoard();
    communicator.syncBoard(MoveType.x);
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    TurnPlayerDisplay turnPlayerDisplay = TurnPlayerDisplay();

    List<Widget> userInterfaces = [
      SizedBox(height: size.height*0.1),
      turnPlayerDisplay.build(context),
      SizedBox(height: size.height - size.height*0.1 - turnPlayerDisplay.size.height, child: board.build(context))];

    return MaterialApp(
      home: PopScope(
        canPop: false,
        onPopInvoked: (value) {},
        child: Scaffold(
          body: Column(children: userInterfaces),
          floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.ice_skating),
            onPressed: () {promotionDialogBuilder(context);},),
        ),
      ),
    );
  }
}

class Board {
  late List<Cell> _rawCells;

  void init() {
    _rawCells = List.generate(8 * 8, (index) {
      Color color = (index + index ~/ 8) % 2 == 0 ? Colors.white : Colors.black;

      return Cell(color, Position._setIndex(index));
    });
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

  Position._setIndex(this._index) {
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
  late Widget body;
  late Position position;
  late Color color;

  Widget setBody(Widget child) {
    body = GestureDetector(
      onTap: () {
        if (selectedPiece != null) {
          setState(() {
            board.getCell(selectedPiece!.position).isSelected = false;
          });

          communicator.sendMovingRequest(selectedPiece!, selectedPiece!.position, position);
          selectedPiece = null;
        } else if (turnPlayer == color) {
          setState(() {
            selectedPiece = this;
            board.getCell(position).isSelected = true;
          });
        }
      },
      child: child,
    );

    return body;
  }

  Piece(this.color, String lowerImageDirectory) {
    String upperImageDirectory = color == Colors.white ? "assets/pieces/white/" : "assets/pieces/black/";
    AssetImage targetImage = AssetImage("$upperImageDirectory$lowerImageDirectory");

    setBody(
      Image(image: targetImage),
    );
  }
}

class Pawn extends Piece {
  Pawn(Color color) : super(color, 'pawn.png');
}

class Bishop extends Piece {
  Bishop(Color color) : super(color, 'bishop.png');
}

class Knight extends Piece {
  Knight(Color color) : super(color, 'knight.png');
}

class Rook extends Piece {
  bool hasMoved = false;

  Rook(Color color) : super(color, 'rook.png');
}

class Queen extends Piece {
  Queen(Color color) : super(color, 'queen.png');
}

class King extends Piece {
  bool hasMoved = false;

  King(Color color) : super(color, 'king.png');
}

class Cell {
  late Color color;
  late Position position;
  bool isSelected = false;
  Piece? piece;

  Cell(this.color, this.position);

  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Center(
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (selectedPiece != null) {
              board.getCell(selectedPiece!.position).isSelected = false;

              communicator.sendMovingRequest(selectedPiece!, selectedPiece!.position, position);
              selectedPiece = null;
            }
          });
        },
        child: Container(
          color: (isSelected) ? addGreen(color) : color,
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

class TurnPlayerDisplay {
  late Size size;

  Widget build(BuildContext context) {
    Size contextSize = MediaQuery.of(context).size;
    double width = contextSize.width * 0.90;
    double height = contextSize.height * 0.10;
    size = Size(width, height);

    return Center(
      child: SizedBox(
        height: height,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLeftTurnPlayerDisplay(context),
            _buildRightTurnPlayerDisplay(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftTurnPlayerDisplay(BuildContext context) {
    LeftTurnPlayerDisplayPainter leftTurnPlayerDisplayPainter = const LeftTurnPlayerDisplayPainter();
    return CustomPaint(painter: leftTurnPlayerDisplayPainter, size: size / 2);
  }

  Widget _buildRightTurnPlayerDisplay(BuildContext context) {
    RightTurnPlayerDisplayPainter rightTurnPlayerDisplayPainter = const RightTurnPlayerDisplayPainter();
    return CustomPaint(painter: rightTurnPlayerDisplayPainter, size: size / 2);
  }
}

class LeftTurnPlayerDisplayPainter extends CustomPainter {
  const LeftTurnPlayerDisplayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = Colors.white;
    Paint paintBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (turnPlayer == Colors.white) ? 7.0 : 3.0
      ..color = Colors.blue;

    double x = size.width;
    double y = size.height;
    Path path = Path()
      ..moveTo(0 * x, 0 * y)
      ..lineTo(0 * x, 1 * y)
      ..lineTo(1 * x, 1 * y)
      ..lineTo(1 * x - 1 * y, 0 * y)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, paintBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class RightTurnPlayerDisplayPainter extends CustomPainter {
  const RightTurnPlayerDisplayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = Colors.black;
    Paint paintBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (turnPlayer == Colors.black) ? 7.0 : 3.0
      ..color = Colors.blue;

    double x = size.width;
    double y = size.height;
    Path path = Path()
      ..moveTo(0 * x, 0 * y)
      ..lineTo(0 * x + 1 * y, 1 * y)
      ..lineTo(1 * x, 1 * y)
      ..lineTo(1 * x, 0 * y)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, paintBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

const greenWhite = Color(0xFFAAFFAA);
const greenBlack = Color(0xFF005500);

Color addGreen(Color color) {
  if (color == Colors.white) {
    return greenWhite;
  } else {
    return greenBlack;
  }
}

// https://api.flutter.dev/flutter/material/showDialog.html
Future<void> winDialogBuilder(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('White Wins!'),
        content: const Text(
          'Win by Checkmate',
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              textStyle: Theme.of(context).textTheme.labelLarge,
            ),
            child: const Text('Confirm'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

// https://api.flutter.dev/flutter/material/showDialog.html
Future<void> promotionDialogBuilder(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              textStyle: Theme.of(context).textTheme.labelLarge,
            ),
            child: const Text("Queen"),
            onPressed: () {
              communicator.promotePiece = Queen;
            },
          ),
          TextButton(
            style: TextButton.styleFrom(
              textStyle: Theme.of(context).textTheme.labelLarge,
            ),
            child: const Text("Rook"),
            onPressed: () {
              communicator.promotePiece = Rook;
            },
          ),
          TextButton(
            style: TextButton.styleFrom(
              textStyle: Theme.of(context).textTheme.labelLarge,
            ),
            child: const Text("Knight"),
            onPressed: () {
              communicator.promotePiece = Knight;
            },
          ),
          TextButton(
            style: TextButton.styleFrom(
              textStyle: Theme.of(context).textTheme.labelLarge,
            ),
            child: const Text("Bishop"),
            onPressed: () {
              communicator.promotePiece = Bishop;
            },
          ),
        ],
      );
    },
  );
}

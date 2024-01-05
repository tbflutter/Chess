enum Pieces {
  nX,
  wP, wN, wB, wR, wQ, wK,
  bP, bN, bB, bR, bQ, bK
}
enum Player {
  w, b,
}

class ChessBoard {
  static final List<int> boardSize = [8,8]; //가로, 세로
  late List<List<Pieces>> boardState; //기물 위치
  int enpassFile = -1; //앙파상 가능한 열 (0~7은 두칸 전진한 폰의 열 인덱스, -1이면 없음)
  late List<bool> isCastleAble; // 캐슬링 가능 여부 (백킹, 백퀸, 흑킹, 흑퀸)
  Player lastPlayer = Player.w; //현재 턴인 사람

  void initBoard() { //보드 초기화
    boardState = [
      [Pieces.bR, Pieces.bN, Pieces.bB, Pieces.bQ, Pieces.bK, Pieces.bB, Pieces.bN, Pieces.bR,],
      List.generate(boardSize[0], (index) => Pieces.bP),
      List.generate(boardSize[0], (index) => Pieces.nX),
      List.generate(boardSize[0], (index) => Pieces.nX),
      List.generate(boardSize[0], (index) => Pieces.nX),
      List.generate(boardSize[0], (index) => Pieces.nX),
      List.generate(boardSize[0], (index) => Pieces.wP),
      [Pieces.wR, Pieces.wN, Pieces.wB, Pieces.wQ, Pieces.wK, Pieces.wB, Pieces.wN, Pieces.wR,],
    ];
    isCastleAble = [true, true, true, true];
  }

}
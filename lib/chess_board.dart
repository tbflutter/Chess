enum Pieces { // 기물 목록
  nX(Player.n, PieceType.X),
  wP(Player.w, PieceType.P), wN(Player.w, PieceType.N), wB(Player.w, PieceType.B),
  wR(Player.w, PieceType.R), wQ(Player.w, PieceType.Q), wK(Player.w, PieceType.K),
  bP(Player.b, PieceType.P), bN(Player.b, PieceType.N), bB(Player.b, PieceType.B),
  bR(Player.b, PieceType.R), bQ(Player.b, PieceType.Q), bK(Player.b, PieceType.K);

  final Player controller;
  final PieceType pieceType;
  const Pieces(this.controller, this.pieceType);

  factory Pieces.getPiece(Player ctr, PieceType pT) {
    return values.firstWhere((e) => e.controller == ctr && e.pieceType == pT);
  }
}
enum Player { // 흰색, 검은색, 중립
  w, b, n
}
enum PieceType { // 없음, 폰, 나이트, 비숍, 룩, 퀸, 킹
  X, P, N, B, R, Q, K
}
enum MoveType { // 이동불가, 일반이동, 잡는이동, 캐슬링 이동, 폰 초기 2칸 전진,
  x, n, c, ca, p2, pm, cpm, ep // 폰 이동 후 프로모션, 폰 잡기 후 프로모션, 앙파상
}
enum CastleType {
  wK, wQ, bK, bQ, // 캐슬링(백 킹사이드, 백 퀸사이드, 흑 킹사이드, 흑 퀸사이드)
}

class ChessBoard {
  static final List<int> boardSize = [8,8]; //가로, 세로
  late List<List<Pieces>> boardState; //기물 위치
  int epFile = -1; // 앙파상 가능한 열 (0~7은 두칸 전진한 폰의 열 인덱스, -1이면 없음)
  int drawClock = 0; // 마지막으로 기물을 잡거나 폰을 전진한 후 지난 턴의 수, 75가 되면 무승부
  late Map<CastleType, bool> isCastleAble; // 캐슬링 가능 여부
  Player lastPlayer = Player.w; //현재 턴인 사람
  int fw() => (lastPlayer == Player.w ? -1 : 1); // 폰이 이동하는 방향
  int pmRank() => (lastPlayer == Player.w ? 0 : boardSize[1] - 1); //폰이 프로모션하는 랭크(세로 좌표)

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
    ]; // 초기 보드 상태
    isCastleAble = {
      CastleType.wK : true,
      CastleType.wQ : true,
      CastleType.bK : true,
      CastleType.bQ : true,
    }; // 모든 캐슬링(백킹, 백퀸, 흑킹, 흑퀸) 가능으로 설정
  }

  // posStart(시작좌표), posEnd (끝좌표)를 받아 시작좌표의 기물이 끝좌표로 이동할때의 이동 방식을 리턴
  MoveType findMoveType(List<int> posStart, List<int> posEnd) {
    if(posStart[0] <= -1 || posStart[0] >= boardSize[0] || posStart[1] <= -1 || posStart[1] >= boardSize[1]){
      return MoveType.x; // 보드 외부에 이동 시도
    }

    List<List<Pieces>> tempBoardState = boardState;
    Pieces startPiece = tempBoardState[posStart[1]][posStart[0]];
    Pieces endPiece = tempBoardState[posEnd[1]][posEnd[0]];

    tempBoardState[posEnd[1]][posEnd[0]] = startPiece;
    tempBoardState[posStart[1]][posStart[0]] = Pieces.nX;

    if(isChecked(tempBoardState)){
      return MoveType.x;
    }
    else{
      if(endPiece == Pieces.nX){
        if(startPiece.pieceType == PieceType.P || (posStart[1] + fw()) == pmRank()){
          return MoveType.pm;
        }
        return MoveType.n;
      }
      else if(endPiece.controller == lastPlayer){
        return MoveType.x;
      }
      else{
        if(startPiece.pieceType == PieceType.P || (posStart[1] + fw()) == pmRank()){
          return MoveType.cpm;
        }
        return MoveType.c;
      }
    }
  }

  // pos(보드의 좌표)를 받아 이동 가능한 칸의 배열(보드 크기와 동일)을 리턴
  List<List<MoveType>> moveCalc(List<int> pos) {
    List<List<MoveType>> tempMove = List.generate(boardSize[1], (index) => List.generate(boardSize[0], (index) => MoveType.x));
    if(boardState[pos[1]][pos[0]].controller != lastPlayer) { // 선택한 기물이 자신의 기물이 아닐 경우
      return tempMove;
    }
    else{
      switch(boardState[pos[1]][pos[0]].pieceType){
        case PieceType.P: // 폰일 경우
          int startRank = (lastPlayer == Player.w ? boardSize[1] - 2 : 1);
          int epRank = (lastPlayer == Player.w ? 3 : boardSize[1] - 4);

          if(boardState[pos[1] + fw()][pos[0]] == Pieces.nX) { // 첫 전진
            tempMove[pos[1] + fw()][pos[0]] = findMoveType(pos, [pos[0], pos[1] + fw()]);
            if(pos[1] == startRank){ // 2번째 전진
              if(boardState[pos[1] + 2*fw()][pos[0]].pieceType == PieceType.X) {
                MoveType move = findMoveType(pos, [pos[0], pos[1] + 2*fw()]);
                if(move != MoveType.x) tempMove[pos[1] + 2*fw()][pos[0]] = MoveType.p2;
              }
            }
          }
          if(pos[0] - 1 > -1){ // 왼쪽 대각선 잡기
            if(boardState[pos[1] + fw()][pos[0] - 1].pieceType != PieceType.X) {
              tempMove[pos[1] + fw()][pos[0] - 1] = findMoveType(pos, [pos[0] - 1, pos[1] + fw()]);
            }
            if(epFile == pos[0] - 1 && pos[0] == epRank){ // 앙파상 왼쪽
              List<List<Pieces>> tempBoardState = boardState;
              Pieces tempPiece = tempBoardState[pos[1]][pos[0]];

              tempBoardState[pos[1]][pos[0] - 1] = Pieces.nX;
              tempBoardState[pos[1] + fw()][pos[0] - 1] = tempPiece;
              tempBoardState[pos[1]][pos[0]] = Pieces.nX;
              if(isChecked(tempBoardState)) {
                tempMove[pos[1] + fw()][pos[0] - 1] = MoveType.ep;
              }
            }
          }
          if(pos[0] + 1 < boardSize[0]){ // 오른쪽 대각선 잡기
            if(boardState[pos[1] + fw()][pos[0] + 1].pieceType != PieceType.X) {
              tempMove[pos[1] + fw()][pos[0] + 1] = findMoveType(pos, [pos[0] + 1, pos[1] + fw()]);
            }
            if(epFile == pos[0] + 1 && pos[0] == epRank){ // 앙파상 오른쪽
              List<List<Pieces>> tempBoardState = boardState;
              Pieces tempPiece = tempBoardState[pos[1]][pos[0]];

              tempBoardState[pos[1]][pos[0] + 1] = Pieces.nX;
              tempBoardState[pos[1] + fw()][pos[0] + 1] = tempPiece;
              tempBoardState[pos[1]][pos[0]] = Pieces.nX;
              if(isChecked(tempBoardState)) {
                tempMove[pos[1] + fw()][pos[0] + 1] = MoveType.ep;
              }
            }
          }
          return tempMove;

        case PieceType.N: // 나이트일 경우 8방향 각각에 대해 판단
          if(pos[0] - 2 > -1 && pos[1] - 1 > -1) {
            tempMove[pos[1] - 1][pos[0] - 2] = findMoveType(pos, [pos[0] - 2, pos[1] - 1]);
          }
          if(pos[0] - 1 > -1 && pos[1] - 2 > -1) {
            tempMove[pos[1] - 2][pos[0] - 1] = findMoveType(pos, [pos[0] - 1, pos[1] - 2]);
          }
          if(pos[0] - 2 > -1 && pos[1] + 1 < boardSize[1]) {
            tempMove[pos[1] + 1][pos[0] - 2] = findMoveType(pos, [pos[0] - 2, pos[1] + 1]);
          }
          if(pos[0] - 1 > -1 && pos[1] + 2 < boardSize[1]) {
            tempMove[pos[1] + 2][pos[0] - 1] = findMoveType(pos, [pos[0] - 1, pos[1] + 2]);
          }
          if(pos[0] + 2 < boardSize[0] && pos[1] - 1 > -1) {
            tempMove[pos[1] - 1][pos[0] + 2] = findMoveType(pos, [pos[0] + 2, pos[1] - 1]);
          }
          if(pos[0] + 1 < boardSize[0] && pos[1] - 2 > -1) {
            tempMove[pos[1] - 2][pos[0] + 1] = findMoveType(pos, [pos[0] + 1, pos[1] - 2]);
          }
          if(pos[0] + 2 < boardSize[0] && pos[1] + 1 < boardSize[1]) {
            tempMove[pos[1] + 1][pos[0] + 2] = findMoveType(pos, [pos[0] + 2, pos[1] + 1]);
          }
          if(pos[0] + 1 < boardSize[0] && pos[1] + 2 < boardSize[1]) {
            tempMove[pos[1] + 2][pos[0] + 1] = findMoveType(pos, [pos[0] + 1, pos[1] + 2]);
          }
          return tempMove;

        case PieceType.B: // 비숍일 경우
          for(int i = 1; i < (boardSize[0] + boardSize[1]); i++) { //4방향에 대해 판단
            if(pos[0] - i > -1 || pos[1] - i > -1) break;
            tempMove[pos[1] - i][pos[0] - i] = findMoveType(pos, [pos[0] - i, pos[1] - i]);
            if(boardState[pos[1] - i][pos[0] - i].pieceType != PieceType.X) break;
          }
          for(int i = 1; i < (boardSize[0] + boardSize[1]); i++) {
            if(pos[0] - i > -1 || pos[1] - i < boardSize[1]) break;
            tempMove[pos[1] + i][pos[0] - i] = findMoveType(pos, [pos[0] - i, pos[1] + i]);
            if(boardState[pos[1] + i][pos[0] - i].pieceType != PieceType.X) break;
          }
          for(int i = 1; i < (boardSize[0] + boardSize[1]); i++) {
            if(pos[0] + i < boardSize[0] || pos[1] - i > -1) break;
            tempMove[pos[1] - i][pos[0] + i] = findMoveType(pos, [pos[0] + i, pos[1] - i]);
            if(boardState[pos[1] - i][pos[0] + i].pieceType != PieceType.X) break;
          }
          for(int i = 1; i < (boardSize[0] + boardSize[1]); i++) {
            if(pos[0] + i < boardSize[0] || pos[1] - i < boardSize[1]) break;
            tempMove[pos[1] + i][pos[0] + i] = findMoveType(pos, [pos[0] + i, pos[1] + i]);
            if(boardState[pos[1] + i][pos[0] + i].pieceType != PieceType.X) break;
          }
          return tempMove;

        case PieceType.R: //룩일 경우
          for(int i = 1; i < boardSize[1]; i++) { //4방향에 대해 판단
            if(pos[1] - i > -1) break;
            tempMove[pos[1] - i][pos[0]] = findMoveType(pos, [pos[0], pos[1] - i]);
            if(boardState[pos[1] - i][pos[0]].pieceType != PieceType.X) break;
          }
          for(int i = 1; i < boardSize[1]; i++) {
            if(pos[1] - i < boardSize[1]) break;
            tempMove[pos[1] + i][pos[0]] = findMoveType(pos, [pos[0], pos[1] + i]);
            if(boardState[pos[1] + i][pos[0]].pieceType != PieceType.X) break;
          }
          for(int i = 1; i < boardSize[0]; i++) {
            if(pos[0] - i > -1) break;
            tempMove[pos[1]][pos[0] - i] = findMoveType(pos, [pos[0] - i, pos[1]]);
            if(boardState[pos[1]][pos[0] - i].pieceType != PieceType.X) break;
          }
          for(int i = 1; i < boardSize[0]; i++) {
            if(pos[0] + i < boardSize[0]) break;
            tempMove[pos[1]][pos[0] + i] = findMoveType(pos, [pos[0] + i, pos[1]]);
            if(boardState[pos[1]][pos[0] + i].pieceType != PieceType.X) break;
          }
          return tempMove;

        case PieceType.Q: // 퀸일 경우
          for(int i = 1; i < boardSize[1]; i++) { //4방향에 대해 판단
            if(pos[1] - i > -1) break;
            tempMove[pos[1] - i][pos[0]] = findMoveType(pos, [pos[0], pos[1] - i]);
            if(boardState[pos[1] - i][pos[0]].pieceType != PieceType.X) break;
          }
          for(int i = 1; i < boardSize[1]; i++) {
            if(pos[1] - i < boardSize[1]) break;
            tempMove[pos[1] + i][pos[0]] = findMoveType(pos, [pos[0], pos[1] + i]);
            if(boardState[pos[1] + i][pos[0]].pieceType != PieceType.X) break;
          }
          for(int i = 1; i < boardSize[0]; i++) {
            if(pos[0] - i > -1) break;
            tempMove[pos[1]][pos[0] - i] = findMoveType(pos, [pos[0] - i, pos[1]]);
            if(boardState[pos[1]][pos[0] - i].pieceType != PieceType.X) break;
          }
          for(int i = 1; i < boardSize[0]; i++) {
            if(pos[0] + i < boardSize[0]) break;
            tempMove[pos[1]][pos[0] + i] = findMoveType(pos, [pos[0] + i, pos[1]]);
            if(boardState[pos[1]][pos[0] + i].pieceType != PieceType.X) break;
          } // 여기까지 룩 로직
          for(int i = 1; i < (boardSize[0] + boardSize[1]); i++) { //4방향에 대해 판단
            if(pos[0] - i > -1 || pos[1] - i > -1) break;
            tempMove[pos[1] - i][pos[0] - i] = findMoveType(pos, [pos[0] - i, pos[1] - i]);
            if(boardState[pos[1] - i][pos[0] - i].pieceType != PieceType.X) break;
          }
          for(int i = 1; i < (boardSize[0] + boardSize[1]); i++) {
            if(pos[0] - i > -1 || pos[1] - i < boardSize[1]) break;
            tempMove[pos[1] + i][pos[0] - i] = findMoveType(pos, [pos[0] - i, pos[1] + i]);
            if(boardState[pos[1] + i][pos[0] - i].pieceType != PieceType.X) break;
          }
          for(int i = 1; i < (boardSize[0] + boardSize[1]); i++) {
            if(pos[0] + i < boardSize[0] || pos[1] - i > -1) break;
            tempMove[pos[1] - i][pos[0] + i] = findMoveType(pos, [pos[0] + i, pos[1] - i]);
            if(boardState[pos[1] - i][pos[0] + i].pieceType != PieceType.X) break;
          }
          for(int i = 1; i < (boardSize[0] + boardSize[1]); i++) {
            if(pos[0] + i < boardSize[0] || pos[1] - i < boardSize[1]) break;
            tempMove[pos[1] + i][pos[0] + i] = findMoveType(pos, [pos[0] + i, pos[1] + i]);
            if(boardState[pos[1] + i][pos[0] + i].pieceType != PieceType.X) break;
          } // 여기까지 비숍 로직
          return tempMove;

        case PieceType.K: // 킹일 경우
          if(pos[0] - 1 >= 0) {
            tempMove[pos[1]][pos[0] - 1] = findMoveType(pos, [pos[0] - 1, pos[1]]); // 일반 이동
          }
          if(pos[1] - 1 >= 0) {
            tempMove[pos[1] - 1][pos[0]] = findMoveType(pos, [pos[0], pos[1] - 1]);
          }
          if(pos[0] + 1 < boardSize[0]) {
            tempMove[pos[1]][pos[0] + 1] = findMoveType(pos, [pos[0] + 1, pos[1]]);
          }
          if(pos[1] + 1 < boardSize[0]) {
            tempMove[pos[1] + 1][pos[0]] = findMoveType(pos, [pos[0], pos[1] + 1]);
          }
          if(pos[0] - 1 >= 0 && pos[1] - 1 >= 0) {
            tempMove[pos[1] - 1][pos[0] - 1] = findMoveType(pos, [pos[0] - 1, pos[1] - 1]);
          }
          if(pos[0] - 1 >= 0 && pos[1] + 1 < boardSize[1]) {
            tempMove[pos[1] + 1][pos[0] - 1] = findMoveType(pos, [pos[0] - 1, pos[1] + 1]);
          }
          if(pos[0] + 1 < boardSize[0] && pos[1] - 1 >= 0) {
            tempMove[pos[1] - 1][pos[0] + 1] = findMoveType(pos, [pos[0] + 1, pos[1] - 1]);
          }
          if(pos[0] + 1 < boardSize[0] && pos[1] + 1 < boardSize[1]) {
            tempMove[pos[1] + 1][pos[0] + 1] = findMoveType(pos, [pos[0] + 1, pos[1] + 1]);
          }

          if(isCastleAble[lastPlayer == Player.w ? CastleType.wK : CastleType.bK] ?? false){ // 킹사이드 캐슬링
            if(boardState[pos[1]][pos[0] + 1].pieceType == PieceType.X
                || boardState[pos[1]][pos[0] + 2].pieceType == PieceType.X){
              List<List<Pieces>> tempBoardState = boardState;
              Pieces tempPiece = tempBoardState[pos[1]][pos[0]];
              bool castleAble = true;
              tempBoardState[pos[1]][pos[0] + 3] = Pieces.nX;

              tempBoardState[pos[1]][pos[0] + 1] = tempPiece;
              tempBoardState[pos[1]][pos[0]] = Pieces.nX;
              castleAble = castleAble && !isChecked(tempBoardState);
              tempBoardState[pos[1]][pos[0] + 2] = tempPiece;
              tempBoardState[pos[1]][pos[0] + 1] = Pieces.nX;
              castleAble = castleAble && !isChecked(tempBoardState);
              if(castleAble) tempMove[pos[1]][pos[0] + 2] = MoveType.ca;
            }
          }
          if(isCastleAble[lastPlayer == Player.w ? CastleType.wQ : CastleType.bQ] ?? false){ // 퀸사이드 캐슬링
            if(boardState[pos[1]][pos[0] - 1].pieceType == PieceType.X
                || boardState[pos[1]][pos[0] - 2].pieceType == PieceType.X
                || boardState[pos[1]][pos[0] - 3].pieceType == PieceType.X){
              List<List<Pieces>> tempBoardState = boardState;
              Pieces tempPiece = tempBoardState[pos[1]][pos[0]];
              bool castleAble = true;
              tempBoardState[pos[1]][pos[0] - 3] = Pieces.nX;

              tempBoardState[pos[1]][pos[0] - 1] = tempPiece;
              tempBoardState[pos[1]][pos[0]] = Pieces.nX;
              castleAble = castleAble && !isChecked(tempBoardState);
              tempBoardState[pos[1]][pos[0] - 2] = tempPiece;
              tempBoardState[pos[1]][pos[0] - 1] = Pieces.nX;
              castleAble = castleAble && !isChecked(tempBoardState);
              if(castleAble) tempMove[pos[1]][pos[0] - 2] = MoveType.ca;
            }
          }
          return tempMove;

        default:
          return tempMove;
      }
    }
  }

  void syncBoard(MoveType move, List<List<Pieces>> board) {} // 일단 함수가 존재한다고 가정
  PieceType getPromotePiece() {return PieceType.Q;}

  // 두 지점을 입력받아, 이동 처리 후 syncBoard()함수에 이동코드, 보드상태를 전달하는 함수
  // 프로모션 시에는 getPromotePiece()함수를 호출 후 처리 (변경가능)
  // 보드 밖을 참조하거나 불가능한 이동 시에는 이동 처리 없이 이동코드 x로 syncBoard()함수에 전달
  void turnMove(List<int> posStart, List<int> posEnd) {
    if(posStart[0] <= -1 || posStart[0] >= boardSize[0] || posStart[1] <= -1 || posStart[1] >= boardSize[1]){
      syncBoard(MoveType.x, boardState); // 보드 외부에 이동 시도
    }
    else if(posEnd[0] <= -1 || posEnd[0] >= boardSize[0] || posEnd[1] <= -1 || posEnd[1] >= boardSize[1]){
      syncBoard(MoveType.x, boardState); // 보드 외부에 이동 시도
    }

    MoveType move = moveCalc(posStart)[posEnd[1]][posEnd[0]];

    if(move == MoveType.x){
      syncBoard(move, boardState); // 불가능한 이동 시도
    }
    else if(move == MoveType.n || move == MoveType.c || move == MoveType.p2 || move == MoveType.ep){
      moveNormal(move, posStart, posEnd);
      syncBoard(move, boardState);
    }
    else if(move == MoveType.ca){
      if(posEnd[0] == posStart[0] + 2){
        moveCastle(lastPlayer == Player.w ? CastleType.wK : CastleType.bK);
      }
      else if(posEnd[0] == posStart[0] - 2){
        moveCastle(lastPlayer == Player.w ? CastleType.wQ : CastleType.bQ);
      }
      syncBoard(move, boardState);
    }
    else if(move == MoveType.pm || move == MoveType.cpm){
      Pieces promotePiece = Pieces.getPiece(lastPlayer, getPromotePiece());
      movePromote(promotePiece, posStart, posEnd);
      syncBoard(move, boardState);
    }
  }

  int turnPass(){ // 턴을 다음 사람에게 넘긴 후 int 리턴(0이면 정상 처리, 0이 아니면 오류)
    switch(lastPlayer){
      case Player.w:
        lastPlayer = Player.b;
        return 0;
      case Player.b:
        lastPlayer = Player.w;
        return 0;
      case Player.n:
        return 3; // 잘못된 플레이어 턴
    }
  }

  // 이동코드, 이동 시작과 끝 좌표를 받아 이동 처리 후 int 리턴(0이면 정상 처리, 0이 아니면 오류)
  // 가능한 이동코드 : n, c, p2, ep
  int moveNormal(MoveType move, List<int> posStart, List<int> posEnd) {
    if(posStart[0] <= -1 || posStart[0] >= boardSize[0] || posStart[1] <= -1 || posStart[1] >= boardSize[1]){
      return 1; // 보드 외부에 이동 시도
    }
    else if(move == MoveType.n || move == MoveType.c || move == MoveType.p2 || move == MoveType.ep){
      Pieces startPiece = boardState[posStart[1]][posStart[0]];
      boardState[posEnd[1]][posEnd[0]] = startPiece;
      boardState[posStart[1]][posStart[0]] = Pieces.nX;

      if(move == MoveType.p2){
        epFile = posEnd[0];
      }
      else{
        epFile = -1;
        if(move == MoveType.ep){
          boardState[posStart[1] - fw()][posStart[0]] = Pieces.nX;
        }
      }
      if(startPiece.pieceType == PieceType.P || move == MoveType.c){
        drawClock = 0;
      }
      else if(lastPlayer == Player.b){
        drawClock++;
      }

      if(turnPass() != 0){
        return 3; // 잘못된 플레이어 턴
      }
      return 0;
    }
    else{
      return 2; // 올바르지 않은 이동코드
    }
  }

  // 프로모션할 기물, 이동 시작과 끝 좌표를 받아 이동 후 프로모션 처리 후 int 리턴(0이면 정상 처리, 0이 아니면 오류)
  int movePromote(Pieces piece, List<int> posStart, List<int> posEnd) {
    if(posStart[0] <= -1 || posStart[0] >= boardSize[0] || posStart[1] <= -1 || posStart[1] >= boardSize[1]){
      return 1; // 보드 외부에 이동 시도
    }
    else{
      boardState[posEnd[1]][posEnd[0]] = piece;
      boardState[posStart[1]][posStart[0]] = Pieces.nX;

      epFile = -1;
      drawClock = 0;
      if(turnPass() != 0){
        return 3; // 잘못된 플레이어 턴
      }
      return 0;
    }
  }

  // 캐슬링 타입 받고 실제로 캐슬링 처리 후 int 리턴(0이면 정상 처리, 0이 아니면 오류)
  int moveCastle(CastleType castle) {
    if(castle == CastleType.wK){
      Pieces rookiePiece = boardState[boardSize[1] - 1][7];
      boardState[boardSize[1] - 1][4] = Pieces.nX;
      boardState[boardSize[1] - 1][7] = Pieces.nX;
      boardState[boardSize[1] - 1][5] = rookiePiece;
      boardState[boardSize[1] - 1][6] = Pieces.wK;
    }
    else if(castle == CastleType.wQ){
      Pieces rookiePiece = boardState[0][0];
      boardState[boardSize[1] - 1][4] = Pieces.nX;
      boardState[boardSize[1] - 1][0] = Pieces.nX;
      boardState[boardSize[1] - 1][3] = rookiePiece;
      boardState[boardSize[1] - 1][2] = Pieces.bK;
    }
    else if(castle == CastleType.bK){
      Pieces rookiePiece = boardState[0][7];
      boardState[0][4] = Pieces.nX;
      boardState[0][7] = Pieces.nX;
      boardState[0][5] = rookiePiece;
      boardState[0][6] = Pieces.bK;
    }
    else if(castle == CastleType.bQ){
      Pieces rookiePiece = boardState[0][0];
      boardState[0][4] = Pieces.nX;
      boardState[0][0] = Pieces.nX;
      boardState[0][3] = rookiePiece;
      boardState[0][2] = Pieces.bK;
    }
    else{
      return 2; // 올바르지 않은 캐슬링 종류
    }

    epFile = -1;
    drawClock = 0;
    if(turnPass() != 0){
      return 3; // 잘못된 플레이어 턴
    }
    return 0;
  }

///////////////////////////////////
  late int kingposy;
  late int kingposx;

  List<int> KingPos(List<List<Pieces>> boardState) {
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        if (boardState[i][j].pieceType == PieceType.K
            && boardState[i][j].controller == lastPlayer) {
          kingposx = j;
          kingposy = i;
          return [i, j];
        } else {}
      }
    }
    return [-1, -1]; // null 오류 방지
  }

  bool isChecked(List<List<Pieces>> boardState) {// 현재 보드를 주면 체크 여부를 반환하는 함수
    List<int> pos = KingPos(boardState); //킹의 좌표 중심 생각
    final KingPlayer = boardState[pos[1]][pos[0]].controller;//판단 대상 킹의 주인을 변수로 불러옴
    late var CheckCo; //로직에서 체크하는 좌표를 담은 변수로 사용함
    //----1. 룩에 의한 체크 위협 상황 여부 판별----
    for (int i = 1; i < 8; i++) {
      CheckCo = boardState[pos[1] - i][pos[0]];
      if (CheckCo.pieceType == PieceType.X) {} else
      if ((CheckCo.pieceType == PieceType.R && CheckCo.controller != KingPlayer)||
          (CheckCo.pieceType == PieceType.Q && CheckCo.controller != KingPlayer)) {
        return true;
      } else {
        continue;
      }
    } // 아래로 확인
    for (int i = 1; i < 8; i++) {
      CheckCo = boardState[pos[1] + i][pos[0]];
      if (CheckCo.pieceType == PieceType.X) {} else
      if ((CheckCo.pieceType == PieceType.R && CheckCo.controller != KingPlayer)||
          (CheckCo.pieceType == PieceType.Q && CheckCo.controller != KingPlayer)) {
        return true;
      } else {
        continue;
      }
    } // 위로 확인
    for (int i = 1; i < 8; i++) {
      CheckCo = boardState[pos[1]][pos[0] - i];
      if (CheckCo.pieceType == PieceType.X) {} else
      if ((CheckCo.pieceType == PieceType.R && CheckCo.controller != KingPlayer)||
          (CheckCo.pieceType == PieceType.Q && CheckCo.controller != KingPlayer)) {
        return true;
      } else {
        continue;
      }
    } // 좌로 확인
    for (int i = 1; i < 8; i++) {
      CheckCo = boardState[pos[1]][pos[0] + i];
      if (CheckCo.pieceType == PieceType.X) {} else
      if ((CheckCo.pieceType == PieceType.R && CheckCo.controller != KingPlayer)||
          (CheckCo.pieceType == PieceType.Q && CheckCo.controller != KingPlayer)) {
        return true;
      } else {
        continue;
      }
    } // 우로 확인, 룩 확인 종료
    //----2. 비숍에 의한 체크 위협 상황 여부 판별----
    for (int i = 1; i < 8; i++) {
      CheckCo = boardState[pos[1] - i][pos[0] - i];
      if (CheckCo.pieceType == PieceType.X) {} else
      if ((CheckCo.pieceType == PieceType.B && CheckCo.controller != KingPlayer)||
          (CheckCo.pieceType == PieceType.Q && CheckCo.controller != KingPlayer)) {
        return true;
      } else {
        continue;
      }
    } // 좌측 아래 대각선 확인
    for (int i = 1; i < 8; i++) {
      CheckCo = boardState[pos[1] + i][pos[0] - i];
      if (CheckCo.pieceType == PieceType.X) {} else
      if ((CheckCo.pieceType == PieceType.B && CheckCo.controller != KingPlayer)||
          (CheckCo.pieceType == PieceType.Q && CheckCo.controller != KingPlayer)) {
        return true;
      } else {
        continue;
      }
    } // 좌측 위 대각선 확인
    for (int i = 1; i < 8; i++) {
      CheckCo = boardState[pos[1] - i][pos[0] + i];
      if (CheckCo.pieceType == PieceType.X) {} else
      if ((CheckCo.pieceType == PieceType.B && CheckCo.controller != KingPlayer)||
          (CheckCo.pieceType == PieceType.Q && CheckCo.controller != KingPlayer)) {
        return true;
      } else {
        continue;
      }
    } // 우측 아래 대각선 확인
    for (int i = 1; i < 8; i++) {
      CheckCo = boardState[pos[1] + i][pos[0] + i];
      if (CheckCo.pieceType == PieceType.X) {} else
      if ((CheckCo.pieceType == PieceType.B && CheckCo.controller != KingPlayer)||
          (CheckCo.pieceType == PieceType.Q && CheckCo.controller != KingPlayer)) {
        return true;
      } else {
        continue;
      }
    } // 우측 위 대각선 확인, 비숍 확인 종료
    //----3. 나이트에 의한 체크 위협 상황 여부 판별----
    //나이트는 좌표기준 고정된 8개 자리를 확인
    if (pos[0] - 2 > -1 && pos[1] - 1 > -1) {
      if (boardState[pos[1] - 1][pos[0] - 2].pieceType == PieceType.N
          && boardState[pos[1] - 1][pos[0] - 2].controller != KingPlayer) {
        return true;
      } else {}
    }
    if (pos[0] - 1 > -1 && pos[1] - 2 > -1) {
      if (boardState[pos[1] - 2][pos[0] - 1].pieceType == PieceType.N
          && boardState[pos[1] - 2][pos[0] - 1].controller != KingPlayer) {
        return true;
      } else {}
    }
    if (pos[0] - 2 > -1 && pos[1] + 1 < boardSize[1]) {
      if (boardState[pos[1] + 1][pos[0] - 2].pieceType == PieceType.N
          && boardState[pos[1] + 1][pos[0] - 2].controller != KingPlayer) {
        return true;
      } else {}
    }
    if (pos[0] - 1 > -1 && pos[1] + 2 < boardSize[1]) {
      if (boardState[pos[1] + 2][pos[0] - 1].pieceType == PieceType.N
          && boardState[pos[1] + 2][pos[0] - 1].controller != KingPlayer) {
        return true;
      } else {}
    }
    if (pos[0] + 2 < boardSize[0] && pos[1] - 1 > -1) {
      if (boardState[pos[1] - 1][pos[0] + 2].pieceType == PieceType.N
          && boardState[pos[1] - 1][pos[0] + 2].controller != KingPlayer) {
        return true;
      } else {}
    }
    if (pos[0] + 1 < boardSize[0] && pos[1] - 2 > -1) {
      if (boardState[pos[1] - 2][pos[0] + 1].pieceType == PieceType.N
          && boardState[pos[1] - 2][pos[0] + 1].controller != KingPlayer) {
        return true;
      } else {}
    }
    if (pos[0] + 2 < boardSize[0] && pos[1] + 1 < boardSize[1]) {
      if (boardState[pos[1] + 1][pos[0] + 2].pieceType == PieceType.N
          && boardState[pos[1] + 1][pos[0] + 2].controller != KingPlayer) {
        return true;
      } else {}
    }
    if (pos[0] + 1 < boardSize[0] && pos[1] + 2 < boardSize[1]) {
      if (boardState[pos[1] + 2][pos[0] + 1].pieceType == PieceType.N
          && boardState[pos[1] + 2][pos[0] + 1].controller != KingPlayer) {
        return true;
      } else {}
    } //나이트 확인 종료
    //----4.폰에 의한 체크 위협 상황 여부 판별----
    if (pos[0] - 1 > -1 && -1 < pos[1] - fw() && pos[1] - fw() < boardSize[1]) {
      if (boardState[pos[1] - fw()][pos[0] - 1].pieceType == PieceType.P
          && boardState[pos[1] - fw()][pos[0] - 1].controller != KingPlayer) {
        return true;
      } else {}
    }
    if(pos[0] + 1 < boardSize[0] && -1 < pos[1] - fw() && pos[1] - fw() < boardSize[1]) {
      if (boardState[pos[1] - fw()][pos[0] + 1].pieceType == PieceType.P
          && boardState[pos[1] - fw()][pos[0] + 1].controller != KingPlayer) {
        return true;
      } else {}
    }//폰 확인 종료
    return false;
  }

  bool isCheckMate(List<List<Pieces>> boardState, Player Player){
    for (int x = 0; x < 8; x++) {
      for (int y = 0; y < 8; y++) {
        if (boardState[y][x].controller == lastPlayer){
          List<List<MoveType>> possibleMove = moveCalc([x, y]);
          for (int a = 0; a < 8; a++){
            for (int b = 0; b < 8; b++){
              if (possibleMove[a][b] != MoveType.x){
                List<List<Pieces>> ifBoardState = boardState;
                ifBoardState[a][b] = boardState[y][x];
                ifBoardState[y][x] = Pieces.nX;
                if (isChecked(ifBoardState)){
                  return true;
                } else {
                  continue;
                }
              } else {
                continue;
              }
            }
          }//이동 가능한 경우의 수 하나씩 검사 for 문
        } else {
          continue;
        }
      }
    }//현재 상황 보드 한 칸씩 검사 for 문
    return false;
  }
}

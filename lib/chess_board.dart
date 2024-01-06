enum Pieces { // 기물 목록
  nX(Player.n, PieceType.X),
  wP(Player.w, PieceType.P), wN(Player.w, PieceType.N), wB(Player.w, PieceType.B),
  wR(Player.w, PieceType.R), wQ(Player.w, PieceType.Q), wK(Player.w, PieceType.K),
  bP(Player.b, PieceType.P), bN(Player.b, PieceType.N), bB(Player.b, PieceType.B),
  bR(Player.b, PieceType.R), bQ(Player.b, PieceType.Q), bK(Player.b, PieceType.K);

  final Player controller;
  final PieceType pieceType;
  const Pieces(this.controller, this.pieceType);
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

class ChessBoard {
  static final List<int> boardSize = [8,8]; //가로, 세로
  late List<List<Pieces>> boardState; //기물 위치
  int epFile = -1; //앙파상 가능한 열 (0~7은 두칸 전진한 폰의 열 인덱스, -1이면 없음)
  late Map<String, bool> isCastleAble; // 캐슬링 가능 여부
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
      "wKside" : true,
      "wQside" : true,
      "bKside" : true,
      "bQside" : true,
    }; // 모든 캐슬링(백킹, 백퀸, 흑킹, 흑퀸) 가능으로 설정
  }

  // posStart(시작좌표), posEnd (끝좌표)를 받아 시작좌표의 기물이 끝좌표로 이동할때의 이동 방식을 리턴
  MoveType findMoveType(List<int> posStart, List<int> posEnd) {
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

          if(isCastleAble[lastPlayer == Player.w ? "wKside" : "bKside"] ?? false){ // 킹사이드 캐슬링
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
          if(isCastleAble[lastPlayer == Player.w ? "wQside" : "bQside"] ?? false){ // 퀸사이드 캐슬링
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
///////////////////////////////////
  late int kingposy;
  late int kingposx;

  List<int> KingPos(List<List<Pieces>> boardState) {
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        if (boardState[i][j].pieceType == PieceType.K) {
          kingposx = j;
          kingposy = i;
          return [i, j];
        } else {}
      }
    }
    return [-1, -1]; // null 오류 방지
  }

  bool isChecked(List<List<Pieces>> boardState) {
    List<int> pos = KingPos(boardState); //킹의 좌표 중심 생각
    //----1. 룩에 의한 체크 위협 상황 여부 판별----
    for (int i = 1; i < 8; i++) {
      if (boardState[pos[1] - i][pos[0]].pieceType == PieceType.X) {} else
      if (boardState[pos[1] - i][pos[0]].pieceType == PieceType.R ||
          boardState[pos[1] - i][pos[0]].pieceType == PieceType.Q) {
        return true;
      } else {
        break;
      }
    } // 아래로 확인
    for (int i = 1; i < 8; i++) {
      if (boardState[pos[1] + i][pos[0]].pieceType == PieceType.X) {} else
      if (boardState[pos[1] + i][pos[0]].pieceType == PieceType.R ||
          boardState[pos[1] + i][pos[0]].pieceType != PieceType.Q) {
        return true;
      } else {
        break;
      }
    } // 위로 확인
    for (int i = 1; i < 8; i++) {
      if (boardState[pos[1]][pos[0] - i].pieceType == PieceType.X) {} else
      if (boardState[pos[1]][pos[0] - i].pieceType == PieceType.R ||
          boardState[pos[1]][pos[0] - i].pieceType != PieceType.Q) {
        return true;
      } else {
        break;
      }
    } // 좌로 확인
    for (int i = 1; i < 8; i++) {
      if (boardState[pos[1]][pos[0] + i].pieceType == PieceType.X) {} else
      if (boardState[pos[1]][pos[0] + i].pieceType == PieceType.R ||
          boardState[pos[1]][pos[0] + i].pieceType != PieceType.Q) {
        return true;
      } else {
        break;
      }
    } // 우로 확인, 룩 확인 종료
    //----2. 비숍에 의한 체크 위협 상황 여부 판별----
    for (int i = 1; i < 8; i++) {
      if (boardState[pos[1] - i][pos[0] - i].pieceType == PieceType.X) {} else
      if (boardState[pos[1] - i][pos[0] - i].pieceType == PieceType.B ||
          boardState[pos[1] - i][pos[0] - i].pieceType != PieceType.Q) {
        return true;
      } else {
        break;
      }
    } // 좌측 아래 대각선 확인
    for (int i = 1; i < 8; i++) {
      if (boardState[pos[1] + i][pos[0] - i].pieceType == PieceType.X) {} else
      if (boardState[pos[1] + i][pos[0] - i].pieceType == PieceType.B ||
          boardState[pos[1] + i][pos[0] - i].pieceType != PieceType.Q) {
        return true;
      } else {
        break;
      }
    } // 좌측 위 대각선 확인
    for (int i = 1; i < 8; i++) {
      if (boardState[pos[1] - i][pos[0] + i].pieceType == PieceType.X) {} else
      if (boardState[pos[1] - i][pos[0] + i].pieceType == PieceType.B ||
          boardState[pos[1] - i][pos[0] + i].pieceType != PieceType.Q) {
        return true;
      } else {
        break;
      }
    } // 우측 아래 대각선 확인
    for (int i = 1; i < 8; i++) {
      if (boardState[pos[1] + i][pos[0] + i].pieceType == PieceType.X) {} else
      if (boardState[pos[1] + i][pos[0] + i].pieceType == PieceType.B ||
          boardState[pos[1] + i][pos[0] + i].pieceType != PieceType.Q) {
        return true;
      } else {
        break;
      }
    } // 우측 위 대각선 확인, 비숍 확인 종료
    //----3. 나이트에 의한 체크 위협 상황 여부 판별----
    //나이트 및 기타 기물 체크 시 보드에서 나가는지 확인 코드 추가 필요
    if (boardState[pos[1] - 2][pos[0] - 1].pieceType != PieceType.X) {

    }
  }
}

enum Pieces {
  nX(Player.n, PieceType.X),
  wP(Player.w, PieceType.P), wN(Player.w, PieceType.N), wB(Player.w, PieceType.B),
  wR(Player.w, PieceType.R), wQ(Player.w, PieceType.Q), wK(Player.w, PieceType.K),
  bP(Player.b, PieceType.P), bN(Player.b, PieceType.N), bB(Player.b, PieceType.B),
  bR(Player.b, PieceType.R), bQ(Player.b, PieceType.Q), bK(Player.b, PieceType.K);

  final Player controller;
  final PieceType pieceType;
  const Pieces(this.controller, this.pieceType);
}
enum Player {
  w, b, n
}
enum PieceType {
  X, P, N, B, R, Q, K
}
enum MoveType {
  x, n, ca, p2, pm, ep
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
    ]; // 초기 보드 상태
    isCastleAble = [true, true, true, true]; // 흰색 킹사이드, 흰색 퀸사이드, 검은색 킹사이드, 검은색 퀸사이드
  }

  List<List<MoveType>> moveCalc(List<int> pos) {
    if(boardState[pos[1]][pos[0]].controller != lastPlayer) {
      return List.generate(boardSize[1], (index) => List.generate(boardSize[0], (index) => MoveType.x));
    }
    else{
      List<List<MoveType>> tempMove = List.generate(boardSize[1], (index) => List.generate(boardSize[0], (index) => MoveType.x));
      switch(boardState[pos[1]][pos[0]].pieceType){ //TODO: 이동시 체크 확인
        case PieceType.P:
          if(boardState[pos[1] + (lastPlayer == Player.w ? -1 : 1)][pos[0]].pieceType == PieceType.X) {
            tempMove[pos[1] + (lastPlayer == Player.w ? -1 : 1)][pos[0]] = (pos[1] == (lastPlayer == Player.w ? 1 : 7)) ? MoveType.pm : MoveType.n;
            if(pos[1] == (lastPlayer == Player.w ? 6 : 1)){
              if(boardState[pos[1] + (lastPlayer == Player.w ? -2 : 2)][pos[0]].pieceType == PieceType.X) {
                tempMove[pos[1] + (lastPlayer == Player.w ? -2 : 2)][pos[0]] = MoveType.p2;
              }
            }
          }
          if(pos[0] >= 0){
            if(boardState[pos[1] + (lastPlayer == Player.w ? -1 : 1)][pos[0] - 1].pieceType != PieceType.X) {
              tempMove[pos[1] + (lastPlayer == Player.w ? -1 : 1)][pos[0] - 1] = MoveType.n;
            }
          }
          if(pos[0] < boardSize[0]){
            if(boardState[pos[1] + (lastPlayer == Player.w ? -1 : 1)][pos[0] + 1].pieceType != PieceType.X) {
              tempMove[pos[1] + (lastPlayer == Player.w ? -1 : 1)][pos[0] + 1] = MoveType.n;
            }
          }
          return tempMove;

        case PieceType.N:
          if(pos[0] - 2 >= 0 && pos[1] - 1 >= 0) tempMove[pos[1] - 1][pos[0] - 2] = MoveType.n;
          if(pos[0] - 1 >= 0 && pos[1] - 2 >= 0) tempMove[pos[1] - 2][pos[0] - 1] = MoveType.n;
          if(pos[0] - 2 >= 0 && pos[1] + 1 < boardSize[1]) tempMove[pos[1] + 1][pos[0] - 2] = MoveType.n;
          if(pos[0] - 1 >= 0 && pos[1] + 2 < boardSize[1]) tempMove[pos[1] + 2][pos[0] - 1] = MoveType.n;
          if(pos[0] + 2 < boardSize[0] && pos[1] - 1 >= 0) tempMove[pos[1] - 1][pos[0] + 2] = MoveType.n;
          if(pos[0] + 1 < boardSize[0] && pos[1] - 2 >= 0) tempMove[pos[1] - 2][pos[0] + 1] = MoveType.n;
          if(pos[0] + 2 < boardSize[0] && pos[1] + 1 < boardSize[1]) tempMove[pos[1] + 1][pos[0] + 2] = MoveType.n;
          if(pos[0] + 1 < boardSize[0] && pos[1] + 2 < boardSize[1]) tempMove[pos[1] + 2][pos[0] + 1] = MoveType.n;
          return tempMove;

        case PieceType.B:
          for(int i = 1; i < 8; i++) {
            tempMove[pos[1] - i][pos[0] - i] = MoveType.n;
            if(boardState[pos[1] - i][pos[0] - i].pieceType != PieceType.X || pos[0] - i >= 0 || pos[1] - i >= 0) break;
          }
          for(int i = 1; i < 8; i++) {
            tempMove[pos[1] + i][pos[0] - i] = MoveType.n;
            if(boardState[pos[1] + i][pos[0] - i].pieceType != PieceType.X || pos[0] - i >= 0 || pos[1] - i < boardSize[1]) break;
          }
          for(int i = 1; i < 8; i++) {
            tempMove[pos[1] - i][pos[0] + i] = MoveType.n;
            if(boardState[pos[1] - i][pos[0] + i].pieceType != PieceType.X || pos[0] + i < boardSize[0] || pos[1] - i >= 0) break;
          }
          for(int i = 1; i < 8; i++) {
            tempMove[pos[1] + i][pos[0] + i] = MoveType.n;
            if(boardState[pos[1] + i][pos[0] + i].pieceType != PieceType.X || pos[0] + i < boardSize[0] || pos[1] - i < boardSize[1]) break;
          }
          return tempMove;

        case PieceType.R:
          for(int i = 1; i < 8; i++) {
            tempMove[pos[1] - i][pos[0]] = MoveType.n;
            if(boardState[pos[1] - i][pos[0]].pieceType != PieceType.X || pos[1] - i >= 0) break;
          }
          for(int i = 1; i < 8; i++) {
            tempMove[pos[1] + i][pos[0]] = MoveType.n;
            if(boardState[pos[1] + i][pos[0]].pieceType != PieceType.X || pos[1] - i < boardSize[1]) break;
          }
          for(int i = 1; i < 8; i++) {
            tempMove[pos[1]][pos[0] - i] = MoveType.n;
            if(boardState[pos[1]][pos[0] - i].pieceType != PieceType.X || pos[0] - i >= 0) break;
          }
          for(int i = 1; i < 8; i++) {
            tempMove[pos[1]][pos[0] + i] = MoveType.n;
            if(boardState[pos[1]][pos[0] + i].pieceType != PieceType.X || pos[0] + i < boardSize[0]) break;
          }
          return tempMove;

        case PieceType.Q:
        //TODO: 비숍, 룩 로직 완성되면 합쳐서 퀸 구현하기
          return tempMove;

        case PieceType.K:
          if(pos[0] - 1 >= 0) tempMove[pos[1]][pos[0] - 1] = MoveType.n;
          if(pos[1] - 1 >= 0) tempMove[pos[1] - 1][pos[0]] = MoveType.n;
          if(pos[0] + 1 < boardSize[0]) tempMove[pos[1]][pos[0] + 1] = MoveType.n;
          if(pos[1] + 1 < boardSize[0]) tempMove[pos[1] + 1][pos[0]] = MoveType.n;
          if(pos[0] - 1 >= 0 && pos[1] - 1 >= 0) tempMove[pos[1] - 1][pos[0] - 1] = MoveType.n;
          if(pos[0] - 1 >= 0 && pos[1] + 1 < boardSize[1]) tempMove[pos[1] + 1][pos[0] - 1] = MoveType.n;
          if(pos[0] + 1 < boardSize[0] && pos[1] - 1 >= 0) tempMove[pos[1] - 1][pos[0] + 1] = MoveType.n;
          if(pos[0] + 1 < boardSize[0] && pos[1] + 1 < boardSize[1]) tempMove[pos[1] + 1][pos[0] + 1] = MoveType.n;

          if(isCastleAble[lastPlayer == Player.w ? 0 : 2]){
            if(boardState[lastPlayer == Player.w ? 7 : 0][pos[0] + 1].pieceType == PieceType.X
                || boardState[lastPlayer == Player.w ? 7 : 0][pos[0] + 2].pieceType == PieceType.X
                || boardState[lastPlayer == Player.w ? 7 : 0][pos[0] + 3].pieceType == PieceType.X){
              if(true) { //TODO: 경로와 결과위치 체크인지 확인
                tempMove[pos[1]][pos[0] + 2] = MoveType.ca;
              }
            }
          }
          if(isCastleAble[lastPlayer == Player.w ? 1 : 3]){
            if(boardState[lastPlayer == Player.w ? 7 : 0][pos[0] - 1].pieceType == PieceType.X
                || boardState[lastPlayer == Player.w ? 7 : 0][pos[0] - 2].pieceType == PieceType.X
                || boardState[lastPlayer == Player.w ? 7 : 0][pos[0] - 3].pieceType == PieceType.X){
              if(true) { //TODO: 경로와 결과위치 체크인지 확인
                tempMove[pos[1]][pos[0] - 2] = MoveType.ca;
              }
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

  void KingPos(List<List<Pieces>> boardState){
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        if (boardState[i][j].pieceType == PieceType.K) {
          kingposx = j;
          kingposy = i;
        } else {
        }
      }
    }
  }

  bool isChecked(List<int> pos){
    KingPos(boardState); //킹의 좌표 중심 생각
    //----1. 룩에 의한 체크 위협 상황 여부 판별----
    for (int i = 1; i < 8; i++){
      if (boardState[pos[1] - i][pos[0]].pieceType == PieceType.X){
      } else if (boardState[pos[1] - i][pos[0]].pieceType == PieceType.R || boardState[pos[1] - i][pos[0]].pieceType == PieceType.Q){
        return true;
      } else {
        break;
      }
    }// 아래로 확인
    for (int i = 1; i < 8; i++){
      if (boardState[pos[1] + i][pos[0]].pieceType == PieceType.X){
      } else if (boardState[pos[1] + i][pos[0]].pieceType == PieceType.R || boardState[pos[1] + i][pos[0]].pieceType != PieceType.Q){
        return true;
      } else {
        break;
      }
    }// 위로 확인
    for (int i = 1; i < 8; i++){
      if (boardState[pos[1]][pos[0] - i].pieceType == PieceType.X){
      } else if (boardState[pos[1]][pos[0] - i].pieceType == PieceType.R || boardState[pos[1]][pos[0] - i].pieceType != PieceType.Q){
        return true;
      } else {
        break;
      }
    }// 좌로 확인
    for (int i = 1; i < 8; i++){
      if (boardState[pos[1]][pos[0] + i].pieceType == PieceType.X){
      } else if (boardState[pos[1]][pos[0] + i].pieceType == PieceType.R || boardState[pos[1]][pos[0] + i].pieceType != PieceType.Q){
        return true;
      } else {
        break;
      }
    }// 우로 확인, 룩 확인 종료
    //----2. 비숍에 의한 체크 위협 상황 여부 판별----
    for(int i = 1; i < 8; i++) {
      if (boardState[pos[1] - i][pos[0] - i].pieceType == PieceType.X){
      } else if (boardState[pos[1] - i][pos[0] - i].pieceType == PieceType.B || boardState[pos[1] - i][pos[0] - i].pieceType != PieceType.Q){
        return true;
      } else {
        break;
      }
    }// 좌측 아래 대각선 확인
    for(int i = 1; i < 8; i++) {
      if (boardState[pos[1] + i][pos[0] - i].pieceType == PieceType.X){
      } else if (boardState[pos[1] + i][pos[0] - i].pieceType == PieceType.B || boardState[pos[1] + i][pos[0] - i].pieceType != PieceType.Q){
        return true;
      } else {
        break;
      }
    }// 좌측 위 대각선 확인
    for(int i = 1; i < 8; i++) {
      if (boardState[pos[1] - i][pos[0] + i].pieceType == PieceType.X){
      } else if (boardState[pos[1] - i][pos[0] + i].pieceType == PieceType.B || boardState[pos[1] - i][pos[0] + i].pieceType != PieceType.Q){
        return true;
      } else {
        break;
      }
    }// 우측 아래 대각선 확인
    for(int i = 1; i < 8; i++) {
      if (boardState[pos[1] + i][pos[0] + i].pieceType == PieceType.X){
      } else if (boardState[pos[1] + i][pos[0] + i].pieceType == PieceType.B || boardState[pos[1] + i][pos[0] + i].pieceType != PieceType.Q){
        return true;
      } else {
        break;
      }
    }// 우측 위 대각선 확인, 비숍 확인 종료
    //----3. 나이트에 의한 체크 위협 상황 여부 판별----

  }
}

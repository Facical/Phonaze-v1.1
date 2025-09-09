import Foundation

/// 웹 페이지 내에서 스크롤/클릭을 수행하기 위한 JS 스니펫 유틸
enum WebMessageBridge {

    /// 스크롤: dx/dy는 pt(픽셀) 단위 상대 이동으로 가정
    static func scrollJS(dx: Double, dy: Double) -> String {
        // 문서/윈도우 모두에 적용되도록 안전하게 처리
        // 스크롤 가능한 최상위 컨테이너를 찾아 scrollBy 수행
        return """
        (function(){
          try {
            var dx = \(dx), dy = \(dy);
            // 최상위 윈도우 기준 스크롤
            window.scrollBy(dx, dy);
            // 스크롤 안 먹히는 경우, 중앙 요소 기준으로 부모를 찾아 시도
            var cx = Math.max(0, Math.min(window.innerWidth - 1, Math.round(window.innerWidth * 0.5)));
            var cy = Math.max(0, Math.min(window.innerHeight - 1, Math.round(window.innerHeight * 0.5)));
            var el = document.elementFromPoint(cx, cy);
            var tries = 0;
            while (el && tries < 5) {
              if (el.scrollBy) { el.scrollBy(dx, dy); break; }
              el = el.parentElement; tries++;
            }
          } catch(e) { /* no-op */ }
        })();
        """
    }

    /// 클릭: 정규화 좌표(nx, ny ∈ [0,1])를 화면 좌표로 변환하여 그 지점 요소에 클릭 이벤트 디스패치
    static func clickJS(nx: Double, ny: Double) -> String {
        return """
        (function(){
          try {
            var nx = Math.max(0, Math.min(1, \(nx)));
            var ny = Math.max(0, Math.min(1, \(ny)));
            var x  = Math.round((window.innerWidth  - 1) * nx);
            var y  = Math.round((window.innerHeight - 1) * ny);
            var el = document.elementFromPoint(x, y);
            if (!el) return;

            function fire(type) {
              var evt = new MouseEvent(type, {
                bubbles: true, cancelable: true, view: window,
                clientX: x, clientY: y, screenX: x, screenY: y,
                buttons: 1
              });
              el.dispatchEvent(evt);
            }
            fire('mousedown');
            fire('mouseup');
            fire('click');
          } catch(e) { /* no-op */ }
        })();
        """
    }
}

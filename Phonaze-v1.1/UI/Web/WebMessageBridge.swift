import Foundation

/// 웹 페이지 내에서 스크롤/클릭을 수행하기 위한 JS 스니펫 유틸
/// ✅ Vision Pro 네이티브 동작에 최적화
enum WebMessageBridge {

    /// 스크롤: dx/dy는 pt(픽셀) 단위 상대 이동으로 가정
    static func scrollJS(dx: Double, dy: Double) -> String {
        return """
        (function(){
          try {
            var dx = \(dx), dy = \(dy);
            // 최상위 윈도우 기준 스크롤
            window.scrollBy(dx, dy);
            
            // 스크롤이 안 되는 경우 중앙 요소의 스크롤 가능한 부모 찾기
            var centerX = window.innerWidth / 2;
            var centerY = window.innerHeight / 2;
            var el = document.elementFromPoint(centerX, centerY);
            
            var attempts = 0;
            while (el && attempts < 3) {
              if (el.scrollBy && (el.scrollHeight > el.clientHeight || el.scrollWidth > el.clientWidth)) {
                el.scrollBy(dx, dy);
                break;
              }
              el = el.parentElement;
              attempts++;
            }
          } catch(e) { 
            console.log('Scroll error:', e);
          }
        })();
        """
    }

    /// ✅ Vision Pro용 간단한 네이티브 클릭
    /// 복잡한 좌표 계산 없이 현재 포커스나 시선 위치를 클릭
    static func nativeTapJS() -> String {
        return """
        (function() {
          try {
            var centerX = window.innerWidth / 2;
            var centerY = window.innerHeight / 2;
            var element = document.elementFromPoint(centerX, centerY);
            if (element) {
              var event = new MouseEvent('click', {
                'view': window,
                'bubbles': true,
                'cancelable': true
              });
              element.dispatchEvent(event);
              return 'Center element clicked: ' + element.tagName;
            }
            return 'No element found at the center.';
          } catch(e) {
            return 'Error: ' + e.message;
          }
        })();
        """
    }
}

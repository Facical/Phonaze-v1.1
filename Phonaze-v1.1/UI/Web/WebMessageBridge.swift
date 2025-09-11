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
        (function(){
          try {
            console.log('Native tap starting');
            
            // 1. 현재 포커스된 요소 확인
            var focusedEl = document.activeElement;
            if (focusedEl && focusedEl !== document.body && focusedEl !== document.documentElement) {
              console.log('Clicking focused element:', focusedEl.tagName);
              focusedEl.click();
              return 'focused_clicked';
            }
            
            // 2. 시선이 있을 가능성이 높은 화면 중앙의 클릭 가능한 요소 찾기
            var centerX = window.innerWidth / 2;
            var centerY = window.innerHeight / 2;
            var centerEl = document.elementFromPoint(centerX, centerY);
            
            if (centerEl) {
              // 클릭 가능한 부모 요소 찾기
              var clickable = centerEl;
              var maxAttempts = 5;
              
              while (clickable && maxAttempts > 0) {
                // 클릭 가능한 요소 판별
                if (clickable.onclick || 
                    clickable.tagName === 'A' || 
                    clickable.tagName === 'BUTTON' || 
                    clickable.tagName === 'INPUT' ||
                    clickable.tagName === 'SELECT' ||
                    clickable.hasAttribute('onclick') ||
                    clickable.classList.contains('clickable') ||
                    clickable.getAttribute('role') === 'button') {
                  
                  console.log('Clicking element:', clickable.tagName);
                  clickable.click();
                  return 'center_clicked';
                }
                clickable = clickable.parentElement;
                maxAttempts--;
              }
            }
            
            // 3. 마지막 대안: 화면 중앙에 마우스 이벤트 발생
            if (centerEl) {
              var evt = new MouseEvent('click', {
                bubbles: true,
                cancelable: true,
                view: window,
                clientX: centerX,
                clientY: centerY
              });
              centerEl.dispatchEvent(evt);
              return 'event_dispatched';
            }
            
            return 'no_action';
          } catch(e) {
            console.log('Native tap error:', e);
            return 'error: ' + e.message;
          }
        })();
        """
    }

    /// ✅ 기존 좌표 기반 클릭 (레거시 호환용)
    static func clickJS(nx: Double, ny: Double) -> String {
        return """
        (function(){
          try {
            var nx = Math.max(0, Math.min(1, \(nx)));
            var ny = Math.max(0, Math.min(1, \(ny)));
            var x  = Math.round((window.innerWidth  - 1) * nx);
            var y  = Math.round((window.innerHeight - 1) * ny);
            var el = document.elementFromPoint(x, y);
            if (!el) return 'no_element';

            function fireEvent(type) {
              var evt = new MouseEvent(type, {
                bubbles: true, cancelable: true, view: window,
                clientX: x, clientY: y, screenX: x, screenY: y,
                buttons: 1
              });
              el.dispatchEvent(evt);
            }
            
            fireEvent('mousedown');
            fireEvent('mouseup');
            fireEvent('click');
            return 'coordinate_clicked';
          } catch(e) { 
            return 'error: ' + e.message;
          }
        })();
        """
    }

    /// ✅ 기존 hoverClickJS 제거됨 - nativeTapJS()로 대체
}

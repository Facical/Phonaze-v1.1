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

    // ✅ Vision Pro 시선 추적 활용 클릭
    static func nativeTapJS() -> String {
        return """
        (function() {
            try {
                console.log('Native tap initiated');
                
                // 1. 현재 hover 상태인 요소들 찾기 (Vision Pro 시선이 머무는 곳)
                var hoveredElements = document.querySelectorAll(':hover');
                console.log('Found', hoveredElements.length, 'hovered elements');
                
                if (hoveredElements.length > 0) {
                    // 가장 깊은(최하위) hover 요소를 클릭
                    var targetElement = hoveredElements[hoveredElements.length - 1];
                    console.log('Clicking hovered element:', targetElement.tagName);
                    
                    // 실제 클릭 이벤트 발생
                    var clickEvent = new MouseEvent('click', {
                        view: window,
                        bubbles: true,
                        cancelable: true,
                        clientX: targetElement.getBoundingClientRect().left + targetElement.offsetWidth / 2,
                        clientY: targetElement.getBoundingClientRect().top + targetElement.offsetHeight / 2
                    });
                    
                    targetElement.dispatchEvent(clickEvent);
                    
                    return 'Clicked element: ' + targetElement.tagName;
                } else {
                    // Hover된 요소가 없으면 화면 중앙 클릭 (fallback)
                    console.log('No hovered element, clicking center');
                    var centerX = window.innerWidth / 2;
                    var centerY = window.innerHeight / 2;
                    var centerElement = document.elementFromPoint(centerX, centerY);
                    
                    if (centerElement) {
                        centerElement.click();
                        return 'Clicked center element: ' + centerElement.tagName;
                    }
                }
                
                return 'No element to click';
            } catch(e) {
                console.error('Native tap error:', e);
                return 'Error: ' + e.message;
            }
        })();
        """
    }

    // ✅ 시선 추적 활성화 스크립트
    static func enableGazeTrackingJS() -> String {
        return """
        (function() {
            console.log('Enabling gaze tracking for Vision Pro');
            
            // Vision Pro의 시선 추적을 위한 CSS 추가
            var style = document.createElement('style');
            style.textContent = `
                /* Vision Pro gaze hover feedback */
                *:hover {
                    outline: 2px solid rgba(0, 122, 255, 0.3) !important;
                    outline-offset: 2px !important;
                    transition: outline 0.15s ease-in-out !important;
                }
                
                a:hover, button:hover, input:hover, select:hover, textarea:hover {
                    outline: 2px solid rgba(0, 122, 255, 0.5) !important;
                    background-color: rgba(0, 122, 255, 0.05) !important;
                }
            `;
            document.head.appendChild(style);
            
            // 현재 hover 요소 추적
            window.__visionProCurrentHover = null;
            document.addEventListener('mouseover', function(e) {
                window.__visionProCurrentHover = e.target;
            }, true);
            
            return 'Gaze tracking enabled';
        })();
        """
    }
}

// Phonaze-v1.1/UI/Web/WebMessageBridge.swift

import Foundation

/// 웹 페이지 내에서 스크롤/클릭을 수행하기 위한 JS 스니펫 유틸
/// ✅ Vision Pro 네이티브 동작에 최적화
enum WebMessageBridge {

    /// 스크롤: dx/dy는 pt(픽셀) 단위 상대 이동
    static func scrollJS(dx: Double, dy: Double) -> String {
        return """
        (function(){
          try {
            var dx = \(dx), dy = \(dy);
            
            // 1. 최상위 윈도우 스크롤 (가장 일반적)
            window.scrollBy({
              left: dx,
              top: dy,
              behavior: 'smooth'
            });
            
            // 2. Netflix/YouTube 특별 처리
            if (window.location.hostname.includes('netflix.com')) {
              var browseContainer = document.querySelector('.browse-container');
              if (browseContainer) {
                browseContainer.scrollBy(dx, dy);
              }
              var mainView = document.querySelector('.mainView');
              if (mainView) {
                mainView.scrollBy(dx, dy);
              }
            }
            
            if (window.location.hostname.includes('youtube.com')) {
              var pageManager = document.querySelector('#page-manager');
              if (pageManager) {
                pageManager.scrollBy(dx, dy);
              }
              var contents = document.querySelector('#contents');
              if (contents) {
                contents.scrollBy(dx, dy);
              }
            }
            
            // 3. 일반적인 스크롤 가능 컨테이너 찾기
            var scrollables = document.querySelectorAll('*');
            for (var i = 0; i < scrollables.length; i++) {
              var el = scrollables[i];
              if (el.scrollHeight > el.clientHeight || el.scrollWidth > el.clientWidth) {
                if (getComputedStyle(el).overflow !== 'hidden' && 
                    getComputedStyle(el).overflowY !== 'hidden') {
                  el.scrollBy(dx, dy);
                }
              }
            }
            
            console.log('Scrolled by:', dx, dy);
            return 'Scroll applied: dx=' + dx + ', dy=' + dy;
          } catch(e) { 
            console.error('Scroll error:', e);
            return 'Scroll error: ' + e.message;
          }
        })();
        """
    }

    /// ✅ Vision Pro 시선 추적 활용 클릭 - :hover 상태의 요소를 클릭
    static func nativeTapJS() -> String {
        return """
        (function() {
          try {
            console.log('Native tap initiated');
            
            // 1. 현재 hover 상태인 요소들 찾기
            var hoveredElements = document.querySelectorAll(':hover');
            console.log('Found', hoveredElements.length, 'hovered elements');
            
            if (hoveredElements.length > 0) {
              // 가장 깊은(최하위) hover 요소를 클릭
              var targetElement = hoveredElements[hoveredElements.length - 1];
              console.log('Clicking hovered element:', targetElement.tagName, targetElement.className || targetElement.id);
              
              // 여러 방법으로 클릭 시도
              
              // 1. 직접 click() 호출
              if (typeof targetElement.click === 'function') {
                targetElement.click();
              }
              
              // 2. MouseEvent 발생
              var clickEvent = new MouseEvent('click', {
                view: window,
                bubbles: true,
                cancelable: true,
                clientX: targetElement.getBoundingClientRect().left + targetElement.offsetWidth / 2,
                clientY: targetElement.getBoundingClientRect().top + targetElement.offsetHeight / 2
              });
              targetElement.dispatchEvent(clickEvent);
              
              // 3. Touch 이벤트 (모바일 호환)
              if (window.TouchEvent) {
                try {
                  var touchEnd = new TouchEvent('touchend', {
                    cancelable: true,
                    bubbles: true,
                    touches: [],
                    targetTouches: [],
                    changedTouches: [{
                      identifier: Date.now(),
                      target: targetElement,
                      clientX: clickEvent.clientX,
                      clientY: clickEvent.clientY,
                      screenX: clickEvent.clientX,
                      screenY: clickEvent.clientY,
                      pageX: clickEvent.clientX + window.pageXOffset,
                      pageY: clickEvent.clientY + window.pageYOffset,
                      radiusX: 1,
                      radiusY: 1,
                      rotationAngle: 0,
                      force: 1
                    }]
                  });
                  targetElement.dispatchEvent(touchEnd);
                } catch(e) {
                  console.log('Touch event failed:', e);
                }
              }
              
              // 4. Pointer 이벤트
              var pointerEvent = new PointerEvent('pointerup', {
                bubbles: true,
                cancelable: true,
                view: window,
                clientX: clickEvent.clientX,
                clientY: clickEvent.clientY,
                pointerId: 1,
                pointerType: 'touch',
                isPrimary: true
              });
              targetElement.dispatchEvent(pointerEvent);
              
              return 'Clicked element: ' + targetElement.tagName + ' ' + (targetElement.id || targetElement.className || '');
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
    
    /// ✅ 시선 추적 활성화 스크립트 - 페이지 로드 시 주입
    static func enableGazeTrackingJS() -> String {
        return """
        (function() {
          console.log('Enabling gaze tracking for Vision Pro');
          
          // 기존 스타일 제거 (중복 방지)
          var existingStyle = document.getElementById('visionpro-gaze-style');
          if (existingStyle) {
            existingStyle.remove();
          }
          
          // Vision Pro의 시선 추적을 위한 CSS 추가
          var style = document.createElement('style');
          style.id = 'visionpro-gaze-style';
          style.textContent = `
            /* Vision Pro gaze hover feedback */
            *:hover {
              outline: 2px solid rgba(0, 122, 255, 0.4) !important;
              outline-offset: 2px !important;
              transition: outline 0.15s ease-in-out !important;
            }
            
            a:hover, button:hover {
              outline: 3px solid rgba(0, 122, 255, 0.6) !important;
              background-color: rgba(0, 122, 255, 0.08) !important;
              transform: scale(1.02);
            }
            
            input:hover, select:hover, textarea:hover {
              outline: 2px solid rgba(0, 122, 255, 0.5) !important;
              background-color: rgba(0, 122, 255, 0.05) !important;
            }
            
            /* Improve clickable area for small elements */
            a, button {
              min-width: 44px;
              min-height: 44px;
              display: inline-flex;
              align-items: center;
              justify-content: center;
            }
            
            /* Netflix specific */
            .title-card:hover, .bob-card:hover {
              transform: scale(1.05) !important;
              z-index: 10 !important;
            }
            
            /* YouTube specific */
            ytd-thumbnail:hover, ytd-video-renderer:hover {
              transform: scale(1.02) !important;
              box-shadow: 0 4px 20px rgba(0,0,0,0.3) !important;
            }
          `;
          document.head.appendChild(style);
          
          // Hover 이벤트 로깅
          var logHover = function(e) {
            var target = e.target;
            if (target.tagName === 'A' || 
                target.tagName === 'BUTTON' || 
                target.tagName === 'INPUT' || 
                target.onclick || 
                target.getAttribute('role') === 'button') {
              console.log('Gaze on:', target.tagName, 
                         target.id || target.className || target.textContent?.substring(0, 30));
              
              // Vision Pro 전용 hover 상태 저장
              window.__visionProCurrentHover = target;
            }
          };
          
          document.addEventListener('mouseover', logHover, true);
          
          document.addEventListener('mouseout', function(e) {
            if (window.__visionProCurrentHover === e.target) {
              window.__visionProCurrentHover = null;
            }
          }, true);
          
          // 페이지 특별 처리
          if (window.location.hostname.includes('netflix.com')) {
            console.log('Netflix detected - applying special handling');
            // Netflix의 동적 콘텐츠 대응
            var observer = new MutationObserver(function() {
              document.querySelectorAll('.title-card, .bob-card').forEach(function(card) {
                card.style.transition = 'transform 0.2s ease';
              });
            });
            observer.observe(document.body, { childList: true, subtree: true });
          }
          
          if (window.location.hostname.includes('youtube.com')) {
            console.log('YouTube detected - applying special handling');
            // YouTube의 동적 콘텐츠 대응
            var observer = new MutationObserver(function() {
              document.querySelectorAll('ytd-thumbnail, ytd-video-renderer').forEach(function(thumb) {
                thumb.style.transition = 'transform 0.2s ease';
              });
            });
            observer.observe(document.body, { childList: true, subtree: true });
          }
          
          return 'Gaze tracking enabled for ' + window.location.hostname;
        })();
        """
    }
    
    /// ✅ 디버깅용 - 현재 hover 상태 확인
    static func debugHoverStateJS() -> String {
        return """
        (function() {
          var hoveredElements = document.querySelectorAll(':hover');
          var result = {
            count: hoveredElements.length,
            elements: [],
            visionProHover: window.__visionProCurrentHover ? {
              tag: window.__visionProCurrentHover.tagName,
              id: window.__visionProCurrentHover.id,
              class: window.__visionProCurrentHover.className
            } : null
          };
          
          for (var i = 0; i < Math.min(hoveredElements.length, 5); i++) {
            var el = hoveredElements[i];
            result.elements.push({
              tag: el.tagName,
              id: el.id || '',
              class: el.className || '',
              text: el.textContent ? el.textContent.substring(0, 30) : ''
            });
          }
          
          console.log('Hover state:', result);
          return JSON.stringify(result);
        })();
        """
    }
}

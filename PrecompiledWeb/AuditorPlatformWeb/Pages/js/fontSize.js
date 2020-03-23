(function (doc, win) {
    var docEl = doc.documentElement,
        resizeEvt = 'orientationchange' in window ? 'orientationchange' : 'resize',
        recalc = function () {
            var clientWidth = docEl.clientWidth;
            if (!clientWidth) return;
            if(768<clientWidth<=1000){
                docEl.style.fontSize = 100 * (clientWidth / 1000) + 'px';
            }else if(clientWidth<=768){
            	alert("a");
                docEl.style.fontSize ='50px';
            }else{
                docEl.style.fontSize = '100px';
            }
        };		
    if (!doc.addEventListener) return;
    win.addEventListener(resizeEvt, recalc, false);
    doc.addEventListener('DOMContentLoaded', recalc, false);
})(document, window);
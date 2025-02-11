// javascript: (()=>{const s = document.createElement('script'); s.src = 'file:///C:/Users/denis/Projects/FOLDOC/foldoc/pub/js/mouse-keyboard.js'; document.head.appendChild(s)})()

// javascript: (()=>{const s = document.createElement('script'); s.src = 'https://foldoc.org/pub/js/mouse-keyboard.js'; document.head.appendChild(s)})()

(() => {
  const pop = document.createElement('div');

  pop.style.cssText = `
  position: absolute;
  width: 754px;
  height: 134px;
  top: 25%; left: calc(50% - 754px/2);
  z-index: 22;
  font-size: 64pt;
  background-color: aquamarine;
  border-radius: 20px;
  `;

  document.body.appendChild(pop);

  [...'ᶏčęėįšųūž'].forEach(c => {
    const span = document.createElement('span');
    span.style.cssText = `
    display: inline-block;
    width: 65px;
    text-align: center;
    margin-left: 6px;
    margin-top: 7px;
    padding-bottom: 10px;
    padding-right: 10px;
    border: 1px solid grey;
    border-radius: 20px;
    background-color: white;
    `;
    span.textContent = c;
    pop.appendChild(span);
    span.addEventListener('click', event => {
      document.getSelection().removeAllRanges();
      if (event.shiftKey) c = c.toLocaleUpperCase();
      console.log(c);
      navigator.clipboard.writeText(c);
      document.body.removeChild(pop);
    })
  });
})();

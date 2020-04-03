// Visit The Stimulus Handbook for more details 
// https://stimulusjs.org/handbook/introduction
// 
// This example controller works with specially annotated HTML like:
//
// <div data-controller="hello">
//   <h1 data-target="hello.output"></h1>
// </div>

import { Controller } from "stimulus"

export default class extends Controller {
  static targets = []

  connect() {
  }

  copy(event) {
    const copyText = event.currentTarget.querySelector('input')
    copyText.classList.add('animated', 'flash', 'fast')
    // event.currentTarget.dataset.originalTitle = "Copied"
    copyText.select();
    copyText.setSelectionRange(0, 99999);
    document.execCommand("copy");
    copyText.setSelectionRange(0, 0);
    
    event.currentTarget.dataset.tooltip = "Copied"
    // event.currentTarget.querySelector('.tooltiptext').innerHTML = "Copied";
  }
  
  reset(event) {
    event.currentTarget.querySelector('input').classList.remove('animated', 'flash', 'fast')
    event.currentTarget.dataset.tooltip = "Copy to Clipboard"
    // event.currentTarget.querySelector('.tooltiptext').innerHTML = "Copy to clipboard"
  }

  showHint() {
    console.log('show hint')
    document.querySelector('img.webhook-setup').style.display = 'unset';
  }

  hideHint() {
    document.querySelector('img.webhook-setup').style.display = 'none';
  }
}

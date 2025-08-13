document.addEventListener('DOMContentLoaded', function () {
  // Step 1: Remove title attribute from .callout elements before Bootstrap tooltip initialization
  document.querySelectorAll(".callout").forEach(function (callout) {
    callout.removeAttribute("title"); // title 속성 제거
  });

  // Step 2: Initialize Bootstrap tooltips
  var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
  var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
    return new bootstrap.Tooltip(tooltipTriggerEl);
  });
});
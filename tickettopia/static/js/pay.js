document.addEventListener("DOMContentLoaded", function () {
    const agreementCheckbox = document.getElementById("check");
    const payButton = document.getElementById("pay");
  
    // Initial state
    payButton.disabled = true;
    payButton.style.backgroundColor = "#ccc";
    payButton.style.cursor = "not-allowed";

    agreementCheckbox.addEventListener("change", function() {
      if (this.checked) {
        payButton.disabled = false;
        payButton.style.backgroundColor = "#d36d78";
        payButton.style.cursor = "pointer";
      } else {
        payButton.disabled = true;
        payButton.style.backgroundColor = "#ccc";
        payButton.style.cursor = "not-allowed";
      }
    });
  });
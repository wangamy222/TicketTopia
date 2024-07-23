document.addEventListener("DOMContentLoaded", function () {
  const LoginWrapper = document.getElementById("login_modal_wrapper");
  const PayWrapper = document.getElementById("pay_modal_wrapper");
  const menuWrapper = document.getElementById("sidemenu_wrapper");
  const toggleButton = document.getElementById("menu");
  const toggleUserButton = document.getElementById("user");
  const togglePayButton = document.getElementById("pay_in");
  const closeButtons = document.querySelectorAll(".close");
  const userNameInput = document.getElementById("userName");
  const priceInput = document.getElementById("price");
  const payInButton = document.getElementById("pay_in");
  const finalPayButton = document.getElementById("pay");
  const mainWrapper = document.getElementById("main_wrapper");

  let loggedInUserName = "";
  if (
    mainWrapper &&
    mainWrapper.dataset &&
    mainWrapper.dataset.loggedInUserName
  ) {
    loggedInUserName = mainWrapper.dataset.loggedInUserName;
  }

  function checkInputs() {
    if (userNameInput && priceInput && payInButton) {
      const enteredName = userNameInput.value.trim();
      const enteredPrice = priceInput.value.trim();

      if (enteredName === loggedInUserName && enteredPrice === "백만원") {
        payInButton.disabled = false;
      } else {
        payInButton.disabled = true;
      }
    }
  }

  if (userNameInput && priceInput) {
    userNameInput.addEventListener("input", checkInputs);
    priceInput.addEventListener("input", checkInputs);
  }

  if (payInButton) {
    payInButton.addEventListener("click", function (event) {
      event.preventDefault();

      const enteredName = userNameInput.value.trim();
      const enteredPrice = priceInput.value.trim();

      if (enteredName !== loggedInUserName) {
        alert("이름이 동일하지 않습니다.");
        return;
      }

      if (enteredPrice !== "백만원") {
        alert("가격이 올바르지 않습니다.");
        return;
      }

      alert("예매가 진행됩니다.");
    });
  }

  if (closeButtons.length > 0) {
    closeButtons.forEach((button) => {
      button.addEventListener("click", () => {
        if (menuWrapper) menuWrapper.classList.remove("active");
        if (LoginWrapper) LoginWrapper.classList.remove("active");
        if (PayWrapper) PayWrapper.classList.remove("active");
      });
    });
  }

  if (toggleButton && menuWrapper) {
    toggleButton.addEventListener("click", () => {
      menuWrapper.classList.add("active");
    });
  }

  if (toggleUserButton && LoginWrapper) {
    toggleUserButton.addEventListener("click", () => {
      LoginWrapper.classList.add("active");
    });
  }

  if (togglePayButton && PayWrapper) {
    togglePayButton.addEventListener("click", (event) => {
      event.preventDefault();
      PayWrapper.classList.add("active");
    });
  }

  if (finalPayButton && PayWrapper) {
    finalPayButton.addEventListener("click", (event) => {
      event.preventDefault(); // Prevent form submission

      // Close the payment modal
      PayWrapper.classList.remove("active");

      // Get the URL from the data attribute
      const reservationCheckUrl = finalPayButton.getAttribute(
        "data-reservationcheck-url"
      );

      // Redirect to the reservation check page
      if (reservationCheckUrl) {
        window.location.href = reservationCheckUrl;
      } else {
        console.error("Reservation check URL not found");
      }
    });
  }
});

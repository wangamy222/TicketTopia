const LoginWrapper = document.getElementById('loin_modal_wrapper');
const menuWrapper = document.getElementById('sidemenu_wrapper');
const toggleButton = document.getElementById('menu'); 
const toggleUserButton = document.getElementById('user'); 
const closeButtons = document.querySelectorAll('.close');

closeButtons.forEach(button => {
  button.addEventListener('click', () => {
    menuWrapper.classList.remove('active');
    LoginWrapper.classList.remove('active');
  });
});

toggleButton.addEventListener('click', () => {
  menuWrapper.classList.add('active');
});

toggleUserButton.addEventListener('click', () => {
    LoginWrapper.classList.add('active');
});


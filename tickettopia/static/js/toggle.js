// notice toggle
document.addEventListener('DOMContentLoaded', function() {
    const infoItems = document.querySelectorAll('#info_text > ol > li.list_title');
  
    infoItems.forEach(item => {
      const title = item.querySelector('.info-title');
      const content = item.querySelector('.info-content');
  
      title.addEventListener('click', function(e) {
        e.stopPropagation();
  
        // Function to hide content
        const hideContent = (element, titleElement) => {
          element.classList.remove('show');
          element.classList.add('hide');
          setTimeout(() => {
            element.style.display = 'none';
            element.classList.remove('hide');
          }, 100); // Faster hiding for all toggles
          if (titleElement) titleElement.style.color = '#fff';
        };
  
        // Close all other toggles
        infoItems.forEach(otherItem => {
          if (otherItem !== item) {
            const otherTitle = otherItem.querySelector('.info-title');
            const otherContent = otherItem.querySelector('.info-content');
            if (otherContent && otherContent.classList.contains('show')) {
              hideContent(otherContent, otherTitle);
            }
          }
        });
  
        // Toggle current item
        if (content) {
          if (content.classList.contains('show')) {
            hideContent(content, title);
          } else {
            content.style.display = 'block';
            content.offsetHeight; // Force a reflow
            content.classList.add('show');
            title.style.color = '#d36d78';
          }
        }
      });
    });
  });

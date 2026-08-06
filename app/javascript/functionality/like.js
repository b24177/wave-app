const like = () => {
  const hearts = document.querySelectorAll('.fa-heart');
  hearts.forEach((heart)=>{
    heart.addEventListener('click', () => {
      if (heart.classList.contains('fa-regular')) {
        heart.classList.remove('fa-regular');
        heart.classList.add('fa-solid');
      }
      else if (heart.classList.contains('fa-solid')) {
        heart.classList.remove('fa-solid');
        heart.classList.add('fa-regular');
      }
    })
  })
}
export { like };

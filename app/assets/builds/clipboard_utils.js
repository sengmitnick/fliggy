// app/javascript/clipboard_utils.ts
function copyToClipboard(text) {
  return new Promise((resolve, reject) => {
    if (navigator.clipboard && window.isSecureContext) {
      navigator.clipboard.writeText(text).then(() => resolve(true)).catch(() => {
        if (fallbackCopy(text)) {
          resolve(true);
        } else {
          reject(new Error("Copy failed"));
        }
      });
    } else {
      if (fallbackCopy(text)) {
        resolve(true);
      } else {
        reject(new Error("Copy failed"));
      }
    }
  });
}
function fallbackCopy(text) {
  const textArea = document.createElement("textarea");
  textArea.value = text;
  textArea.style.position = "fixed";
  textArea.style.opacity = "0";
  document.body.appendChild(textArea);
  textArea.select();
  try {
    const success = document.execCommand("copy");
    document.body.removeChild(textArea);
    return success;
  } catch (error) {
    document.body.removeChild(textArea);
    return false;
  }
}
window.copyToClipboard = copyToClipboard;
//# sourceMappingURL=data:application/json;base64,ewogICJ2ZXJzaW9uIjogMywKICAic291cmNlcyI6IFsiLi4vLi4vamF2YXNjcmlwdC9jbGlwYm9hcmRfdXRpbHMudHMiXSwKICAic291cmNlc0NvbnRlbnQiOiBbIi8vIFNpbXBsZSBDbGlwYm9hcmQgVXRpbGl0eVxuLy8gQ29weSB0byBjbGlwYm9hcmQgd2l0aCBmYWxsYmFjayBzdXBwb3J0IGZvciBpZnJhbWUgYW5kIG9sZGVyIGJyb3dzZXJzXG5cbmZ1bmN0aW9uIGNvcHlUb0NsaXBib2FyZCh0ZXh0OiBzdHJpbmcpOiBQcm9taXNlPGJvb2xlYW4+IHtcbiAgcmV0dXJuIG5ldyBQcm9taXNlPGJvb2xlYW4+KChyZXNvbHZlLCByZWplY3QpID0+IHtcbiAgICAvLyBUcnkgbW9kZXJuIENsaXBib2FyZCBBUEkgZmlyc3RcbiAgICBpZiAobmF2aWdhdG9yLmNsaXBib2FyZCAmJiB3aW5kb3cuaXNTZWN1cmVDb250ZXh0KSB7XG4gICAgICBuYXZpZ2F0b3IuY2xpcGJvYXJkLndyaXRlVGV4dCh0ZXh0KVxuICAgICAgICAudGhlbigoKSA9PiByZXNvbHZlKHRydWUpKVxuICAgICAgICAuY2F0Y2goKCkgPT4ge1xuICAgICAgICAgIGlmIChmYWxsYmFja0NvcHkodGV4dCkpIHtcbiAgICAgICAgICAgIHJlc29sdmUodHJ1ZSk7XG4gICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgIHJlamVjdChuZXcgRXJyb3IoJ0NvcHkgZmFpbGVkJykpO1xuICAgICAgICAgIH1cbiAgICAgICAgfSk7XG4gICAgfSBlbHNlIHtcbiAgICAgIGlmIChmYWxsYmFja0NvcHkodGV4dCkpIHtcbiAgICAgICAgcmVzb2x2ZSh0cnVlKTtcbiAgICAgIH0gZWxzZSB7XG4gICAgICAgIHJlamVjdChuZXcgRXJyb3IoJ0NvcHkgZmFpbGVkJykpO1xuICAgICAgfVxuICAgIH1cbiAgfSk7XG59XG5cbmZ1bmN0aW9uIGZhbGxiYWNrQ29weSh0ZXh0OiBzdHJpbmcpOiBib29sZWFuIHtcbiAgY29uc3QgdGV4dEFyZWEgPSBkb2N1bWVudC5jcmVhdGVFbGVtZW50KCd0ZXh0YXJlYScpO1xuICB0ZXh0QXJlYS52YWx1ZSA9IHRleHQ7XG4gIHRleHRBcmVhLnN0eWxlLnBvc2l0aW9uID0gJ2ZpeGVkJztcbiAgdGV4dEFyZWEuc3R5bGUub3BhY2l0eSA9ICcwJztcbiAgZG9jdW1lbnQuYm9keS5hcHBlbmRDaGlsZCh0ZXh0QXJlYSk7XG4gIHRleHRBcmVhLnNlbGVjdCgpO1xuXG4gIHRyeSB7XG4gICAgY29uc3Qgc3VjY2VzcyA9IGRvY3VtZW50LmV4ZWNDb21tYW5kKCdjb3B5Jyk7XG4gICAgZG9jdW1lbnQuYm9keS5yZW1vdmVDaGlsZCh0ZXh0QXJlYSk7XG4gICAgcmV0dXJuIHN1Y2Nlc3M7XG4gIH0gY2F0Y2ggKGVycm9yKSB7XG4gICAgZG9jdW1lbnQuYm9keS5yZW1vdmVDaGlsZCh0ZXh0QXJlYSk7XG4gICAgcmV0dXJuIGZhbHNlO1xuICB9XG59XG5cbi8vIEV4cG9ydCBnbG9iYWxseVxud2luZG93LmNvcHlUb0NsaXBib2FyZCA9IGNvcHlUb0NsaXBib2FyZDtcbiJdLAogICJtYXBwaW5ncyI6ICI7QUFHQSxTQUFTLGdCQUFnQixNQUFnQztBQUN2RCxTQUFPLElBQUksUUFBaUIsQ0FBQyxTQUFTLFdBQVc7QUFFL0MsUUFBSSxVQUFVLGFBQWEsT0FBTyxpQkFBaUI7QUFDakQsZ0JBQVUsVUFBVSxVQUFVLElBQUksRUFDL0IsS0FBSyxNQUFNLFFBQVEsSUFBSSxDQUFDLEVBQ3hCLE1BQU0sTUFBTTtBQUNYLFlBQUksYUFBYSxJQUFJLEdBQUc7QUFDdEIsa0JBQVEsSUFBSTtBQUFBLFFBQ2QsT0FBTztBQUNMLGlCQUFPLElBQUksTUFBTSxhQUFhLENBQUM7QUFBQSxRQUNqQztBQUFBLE1BQ0YsQ0FBQztBQUFBLElBQ0wsT0FBTztBQUNMLFVBQUksYUFBYSxJQUFJLEdBQUc7QUFDdEIsZ0JBQVEsSUFBSTtBQUFBLE1BQ2QsT0FBTztBQUNMLGVBQU8sSUFBSSxNQUFNLGFBQWEsQ0FBQztBQUFBLE1BQ2pDO0FBQUEsSUFDRjtBQUFBLEVBQ0YsQ0FBQztBQUNIO0FBRUEsU0FBUyxhQUFhLE1BQXVCO0FBQzNDLFFBQU0sV0FBVyxTQUFTLGNBQWMsVUFBVTtBQUNsRCxXQUFTLFFBQVE7QUFDakIsV0FBUyxNQUFNLFdBQVc7QUFDMUIsV0FBUyxNQUFNLFVBQVU7QUFDekIsV0FBUyxLQUFLLFlBQVksUUFBUTtBQUNsQyxXQUFTLE9BQU87QUFFaEIsTUFBSTtBQUNGLFVBQU0sVUFBVSxTQUFTLFlBQVksTUFBTTtBQUMzQyxhQUFTLEtBQUssWUFBWSxRQUFRO0FBQ2xDLFdBQU87QUFBQSxFQUNULFNBQVMsT0FBTztBQUNkLGFBQVMsS0FBSyxZQUFZLFFBQVE7QUFDbEMsV0FBTztBQUFBLEVBQ1Q7QUFDRjtBQUdBLE9BQU8sa0JBQWtCOyIsCiAgIm5hbWVzIjogW10KfQo=

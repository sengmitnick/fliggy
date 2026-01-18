// app/javascript/form_data_patch.ts
(function() {
  const OriginalFormData = window.FormData;
  window.FormData = class PatchedFormData extends OriginalFormData {
    constructor(form) {
      super(form);
      if (form) {
        const disabledFields = form.querySelectorAll(
          "input[disabled][name], textarea[disabled][name], select[disabled][name]"
        );
        disabledFields.forEach((field) => {
          if (field.name && !this.has(field.name)) {
            if (field instanceof HTMLInputElement) {
              if ((field.type === "checkbox" || field.type === "radio") && !field.checked) {
                return;
              }
              if (field.type === "file" && field.files) {
                Array.from(field.files).forEach((file) => {
                  this.append(field.name, file);
                });
                return;
              }
            }
            this.append(field.name, field.value);
          }
        });
      }
    }
  };
  Object.setPrototypeOf(window.FormData, OriginalFormData);
  Object.setPrototypeOf(window.FormData.prototype, OriginalFormData.prototype);
})();
//# sourceMappingURL=data:application/json;base64,ewogICJ2ZXJzaW9uIjogMywKICAic291cmNlcyI6IFsiLi4vLi4vamF2YXNjcmlwdC9mb3JtX2RhdGFfcGF0Y2gudHMiXSwKICAic291cmNlc0NvbnRlbnQiOiBbIi8qKlxuICogRm9ybURhdGEgUGF0Y2ggLSBJbmNsdWRlIGRpc2FibGVkIGZpZWxkc1xuICpcbiAqIEJyb3dzZXIgZGVmYXVsdDogZGlzYWJsZWQgZmllbGRzIGFyZSBOT1Qgc3VibWl0dGVkXG4gKiBUaGlzIHBhdGNoOiBkaXNhYmxlZCBmaWVsZHMgQVJFIHN1Ym1pdHRlZFxuICpcbiAqIFdoeTogQUkgbWF5IGRpc2FibGUgaW5wdXRzIGJlZm9yZSBmb3JtIHN1Ym1pc3Npb24sIGJyZWFraW5nIGZvcm0gZGF0YSBjb2xsZWN0aW9uLlxuICogVGhpcyBwYXRjaCBlbnN1cmVzIGRpc2FibGVkIGZpZWxkcyBhcmUgc3RpbGwgaW5jbHVkZWQgaW4gRm9ybURhdGEuXG4gKi9cblxuKGZ1bmN0aW9uKCkge1xuICBjb25zdCBPcmlnaW5hbEZvcm1EYXRhID0gd2luZG93LkZvcm1EYXRhO1xuXG4gIHdpbmRvdy5Gb3JtRGF0YSA9IGNsYXNzIFBhdGNoZWRGb3JtRGF0YSBleHRlbmRzIE9yaWdpbmFsRm9ybURhdGEge1xuICAgIGNvbnN0cnVjdG9yKGZvcm0/OiBIVE1MRm9ybUVsZW1lbnQpIHtcbiAgICAgIHN1cGVyKGZvcm0pO1xuXG4gICAgICBpZiAoZm9ybSkge1xuICAgICAgICAvLyBDb2xsZWN0IGRpc2FibGVkIGZpZWxkcyB0aGF0IHdvdWxkIG5vcm1hbGx5IGJlIGV4Y2x1ZGVkXG4gICAgICAgIGNvbnN0IGRpc2FibGVkRmllbGRzID0gZm9ybS5xdWVyeVNlbGVjdG9yQWxsPEhUTUxJbnB1dEVsZW1lbnQgfCBIVE1MVGV4dEFyZWFFbGVtZW50IHwgSFRNTFNlbGVjdEVsZW1lbnQ+KFxuICAgICAgICAgICdpbnB1dFtkaXNhYmxlZF1bbmFtZV0sIHRleHRhcmVhW2Rpc2FibGVkXVtuYW1lXSwgc2VsZWN0W2Rpc2FibGVkXVtuYW1lXSdcbiAgICAgICAgKTtcblxuICAgICAgICBkaXNhYmxlZEZpZWxkcy5mb3JFYWNoKGZpZWxkID0+IHtcbiAgICAgICAgICAvLyBPbmx5IGFkZCBpZiBmaWVsZCBoYXMgYSBuYW1lIGFuZCB3YXNuJ3QgYWxyZWFkeSBhZGRlZFxuICAgICAgICAgIGlmIChmaWVsZC5uYW1lICYmICF0aGlzLmhhcyhmaWVsZC5uYW1lKSkge1xuICAgICAgICAgICAgaWYgKGZpZWxkIGluc3RhbmNlb2YgSFRNTElucHV0RWxlbWVudCkge1xuICAgICAgICAgICAgICAvLyBIYW5kbGUgY2hlY2tib3hlcyBhbmQgcmFkaW9zXG4gICAgICAgICAgICAgIGlmICgoZmllbGQudHlwZSA9PT0gJ2NoZWNrYm94JyB8fCBmaWVsZC50eXBlID09PSAncmFkaW8nKSAmJiAhZmllbGQuY2hlY2tlZCkge1xuICAgICAgICAgICAgICAgIHJldHVybjsgLy8gU2tpcCB1bmNoZWNrZWQgY2hlY2tib3hlcy9yYWRpb3NcbiAgICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICAgIC8vIEhhbmRsZSBmaWxlIGlucHV0c1xuICAgICAgICAgICAgICBpZiAoZmllbGQudHlwZSA9PT0gJ2ZpbGUnICYmIGZpZWxkLmZpbGVzKSB7XG4gICAgICAgICAgICAgICAgQXJyYXkuZnJvbShmaWVsZC5maWxlcykuZm9yRWFjaChmaWxlID0+IHtcbiAgICAgICAgICAgICAgICAgIHRoaXMuYXBwZW5kKGZpZWxkLm5hbWUsIGZpbGUpO1xuICAgICAgICAgICAgICAgIH0pO1xuICAgICAgICAgICAgICAgIHJldHVybjtcbiAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICAvLyBBZGQgcmVndWxhciBmaWVsZCB2YWx1ZVxuICAgICAgICAgICAgdGhpcy5hcHBlbmQoZmllbGQubmFtZSwgZmllbGQudmFsdWUpO1xuICAgICAgICAgIH1cbiAgICAgICAgfSk7XG4gICAgICB9XG4gICAgfVxuICB9IGFzIGFueTtcblxuICAvLyBQcmVzZXJ2ZSBzdGF0aWMgbWV0aG9kc1xuICBPYmplY3Quc2V0UHJvdG90eXBlT2Yod2luZG93LkZvcm1EYXRhLCBPcmlnaW5hbEZvcm1EYXRhKTtcbiAgT2JqZWN0LnNldFByb3RvdHlwZU9mKHdpbmRvdy5Gb3JtRGF0YS5wcm90b3R5cGUsIE9yaWdpbmFsRm9ybURhdGEucHJvdG90eXBlKTtcbn0pKCk7XG4iXSwKICAibWFwcGluZ3MiOiAiO0NBVUMsV0FBVztBQUNWLFFBQU0sbUJBQW1CLE9BQU87QUFFaEMsU0FBTyxXQUFXLE1BQU0sd0JBQXdCLGlCQUFpQjtBQUFBLElBQy9ELFlBQVksTUFBd0I7QUFDbEMsWUFBTSxJQUFJO0FBRVYsVUFBSSxNQUFNO0FBRVIsY0FBTSxpQkFBaUIsS0FBSztBQUFBLFVBQzFCO0FBQUEsUUFDRjtBQUVBLHVCQUFlLFFBQVEsV0FBUztBQUU5QixjQUFJLE1BQU0sUUFBUSxDQUFDLEtBQUssSUFBSSxNQUFNLElBQUksR0FBRztBQUN2QyxnQkFBSSxpQkFBaUIsa0JBQWtCO0FBRXJDLG1CQUFLLE1BQU0sU0FBUyxjQUFjLE1BQU0sU0FBUyxZQUFZLENBQUMsTUFBTSxTQUFTO0FBQzNFO0FBQUEsY0FDRjtBQUdBLGtCQUFJLE1BQU0sU0FBUyxVQUFVLE1BQU0sT0FBTztBQUN4QyxzQkFBTSxLQUFLLE1BQU0sS0FBSyxFQUFFLFFBQVEsVUFBUTtBQUN0Qyx1QkFBSyxPQUFPLE1BQU0sTUFBTSxJQUFJO0FBQUEsZ0JBQzlCLENBQUM7QUFDRDtBQUFBLGNBQ0Y7QUFBQSxZQUNGO0FBR0EsaUJBQUssT0FBTyxNQUFNLE1BQU0sTUFBTSxLQUFLO0FBQUEsVUFDckM7QUFBQSxRQUNGLENBQUM7QUFBQSxNQUNIO0FBQUEsSUFDRjtBQUFBLEVBQ0Y7QUFHQSxTQUFPLGVBQWUsT0FBTyxVQUFVLGdCQUFnQjtBQUN2RCxTQUFPLGVBQWUsT0FBTyxTQUFTLFdBQVcsaUJBQWlCLFNBQVM7QUFDN0UsR0FBRzsiLAogICJuYW1lcyI6IFtdCn0K

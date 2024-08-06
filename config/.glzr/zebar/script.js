export function focusWorkspace(event, context) {
  console.log('Focus button clicked!', event, context);
  const id = event.target.id;
  context.providers.glazewm.focusWorkspace(id);
}

export function getMedia(event, context) {
  console.log("Media get!", event, context);
  const reader = new FileReader();
}
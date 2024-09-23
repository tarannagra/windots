export const focusWorkspace = (event, context) => {
    const id = event.target.id;
    context.providers.glazewm.focusWorkspace(id);
};
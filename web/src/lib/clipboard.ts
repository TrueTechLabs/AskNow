export async function copyRawMessageContent(content: string) {
  await navigator.clipboard.writeText(content)
}

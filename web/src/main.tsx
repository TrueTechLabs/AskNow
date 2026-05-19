import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import { useAppStore } from './stores/settings'
import App from './components/App'

// Hydrate non-blocking: render shell immediately, load data after
const store = useAppStore.getState()
store.hydrate()

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)

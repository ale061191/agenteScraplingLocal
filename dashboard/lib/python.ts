import { execSync } from 'child_process'
import fs from 'fs'
import path from 'path'

function findPython(): string {
  for (const cmd of ['python3', 'python']) {
    try {
      const out = execSync(`${cmd} --version 2>&1`, { encoding: 'utf-8', timeout: 5000 })
      if (out.toLowerCase().includes('python')) return cmd
    } catch {}
  }
  if (process.platform === 'win32') {
    const localAppData = process.env.LOCALAPPDATA || ''
    const userProfile = process.env.USERPROFILE || ''
    const winPaths = [
      path.join(localAppData, 'Python', 'bin', 'python.exe'),
      path.join(localAppData, 'Programs', 'Python', 'python.exe'),
      path.join(userProfile, 'AppData', 'Local', 'Programs', 'Python', 'Launcher', 'py.exe'),
      'C:\\Python313\\python.exe',
      'C:\\Python312\\python.exe',
      'C:\\Python311\\python.exe',
    ]
    for (const p of winPaths) {
      if (fs.existsSync(p)) return p
    }
  }
  if (process.platform === 'darwin') {
    for (const p of [
      '/usr/local/bin/python3',
      '/opt/homebrew/bin/python3',
      '/usr/bin/python3',
    ]) {
      if (fs.existsSync(p)) return p
    }
  }
  return 'python'
}

export const PYTHON_EXE = findPython()

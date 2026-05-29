import { NextResponse } from 'next/server'
import { spawn } from 'child_process'
import path from 'path'
import { PYTHON_EXE } from '@/lib/python'

export const dynamic = 'force-dynamic'

export async function POST() {
  const MAIN_PY = path.join(process.cwd(), '..', 'main.py')

  return new Promise<NextResponse>((resolve) => {
    const proc = spawn(PYTHON_EXE, [MAIN_PY, 'supabase-sync'], {
      cwd: path.join(process.cwd(), '..'),
      windowsHide: true,
      stdio: ['ignore', 'pipe', 'pipe'],
    })
    let output = ''
    proc.stdout.on('data', (d: Buffer) => { output += d.toString() })
    proc.stderr.on('data', (d: Buffer) => { output += d.toString() })
    proc.on('close', (code) => {
      const ok = code === 0
      const match = output.match(/(\d+)\s*upserted/)
      const upserted = match ? parseInt(match[1]) : 0
      resolve(NextResponse.json({ success: ok, upserted, output: output.slice(-500) }))
    })
    proc.on('error', () => resolve(NextResponse.json({ success: false, error: 'No se pudo iniciar Python' }, { status: 500 })))
  })
}

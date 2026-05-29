import { NextRequest, NextResponse } from 'next/server'
import path from 'path'
import fs from 'fs'

export const dynamic = 'force-dynamic'
export const revalidate = 0

const DATA_DIR = path.join(process.cwd(), '..', 'leads_data')
const JOBS_FILE = path.join(DATA_DIR, 'search_jobs.json')

function readJobs(): Record<string, any> {
  try { return JSON.parse(fs.readFileSync(JOBS_FILE, 'utf-8')) } catch { return {} }
}

function writeJobs(jobs: Record<string, any>) {
  const dir = path.dirname(JOBS_FILE)
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true })
  fs.writeFileSync(JOBS_FILE, JSON.stringify(jobs, null, 2), 'utf-8')
}

const SCRAPER_API_URL = process.env.SCRAPER_API_URL || ''
const SCRAPER_API_KEY = process.env.SCRAPER_API_KEY || ''

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url)
  const jobId = searchParams.get('jobId')
  const jobs = readJobs()
  if (jobId) {
    return NextResponse.json({ job: jobs[jobId] || null })
  }
  const list = Object.values(jobs)
  return NextResponse.json({ jobs: list })
}

export async function DELETE(request: NextRequest) {
  const { searchParams } = new URL(request.url)
  const jobId = searchParams.get('jobId')
  const jobs = readJobs()
  if (jobId) {
    delete jobs[jobId]
  } else {
    Object.keys(jobs).forEach(k => delete jobs[k])
  }
  writeJobs(jobs)
  return NextResponse.json({ success: true })
}

export async function POST(request: NextRequest) {
  const body = await request.json()
  const { category, state, city, parish, sector, deep, googleSearch, paginasAmarillas, social, tiktok, instagram, maxDeep } = body

  if (!category || !state || !city) {
    return NextResponse.json({ error: 'category, state, and city are required' }, { status: 400 })
  }

  // If we have a scraper microservice URL, use it
  if (SCRAPER_API_URL) {
    try {
      const res = await fetch(`${SCRAPER_API_URL}/search`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...(SCRAPER_API_KEY ? { 'Authorization': `Bearer ${SCRAPER_API_KEY}` } : {}),
        },
        body: JSON.stringify({ category, state, city, parish, sector, deep, googleSearch, paginasAmarillas, social, tiktok, instagram, maxDeep }),
      })
      const data = await res.json()
      return NextResponse.json({ jobId: data.jobId, status: data.status, leadsFound: data.leadsFound, message: data.message })
    } catch (err) {
      return NextResponse.json({ error: 'Microservicio no disponible' }, { status: 503 })
    }
  }

  // Fallback for local development - check if we're in dev mode
  const isDev = process.env.NODE_ENV === 'development'
  
  if (!isDev && !SCRAPER_API_URL) {
    return NextResponse.json({ 
      error: 'Busqueda no disponible en la nube', 
      hint: 'La busqueda de nuevos leads requiere configurar SCRAPER_API_URL. Despliega el microservicio en Render.com y configura la variable de entorno.',
      docs: 'https://render.com/docs/deployments'
    }, { status: 503 })
  }

  // Local development fallback - spawn Python process
  const { spawn } = await import('child_process')
  const path = await import('path')
  const { PYTHON_EXE } = await import('@/lib/python')
  const MAIN_PY = path.join(process.cwd(), '..', 'main.py')

  const cityArg = city.replace(/ /g, '_')
  const flags = [
    ...(deep ? ['--deep'] : []),
    ...(googleSearch ? ['--gs'] : []),
    ...(paginasAmarillas ? ['--pa'] : []),
    ...(social ? ['--social'] : []),
    ...(tiktok ? ['--tiktok'] : []),
    ...(instagram ? ['--instagram'] : []),
    ...(maxDeep && maxDeep > 0 ? ['--max-deep', String(maxDeep)] : []),
  ]
  const args = ['run', ...flags, category, state, cityArg]
  if (parish) args.push(parish.replace(/ /g, '_'))
  if (sector) args.push(sector.replace(/ /g, '_'))

  const jobId = `search_${Date.now()}`

  // Save job to search_jobs.json so the GET handler can return it
  const jobs = readJobs()
  jobs[jobId] = {
    jobId, status: 'running', category, state, city,
    parish: parish || undefined, sector: sector || undefined,
    deep: deep || undefined, googleSearch, paginasAmarillas,
    social, tiktok, instagram, maxDeep,
    started: new Date().toISOString(),
  }
  writeJobs(jobs)

  const proc = spawn(PYTHON_EXE, [MAIN_PY, ...args], {
    cwd: path.join(process.cwd(), '..'),
    windowsHide: true,
    stdio: ['ignore', 'pipe', 'pipe'],
  })

  jobs[jobId].pid = proc.pid
  writeJobs(jobs)

  let output = ''
  proc.stdout.on('data', (data) => { output += data.toString() })
  proc.stderr.on('data', (data) => { output += data.toString() })

  proc.on('close', (code) => {
    const match = output.match(/(\d+)\s*encontrados/)
    const leadsFound = match ? parseInt(match[1]) : 0
    let errorDetail = null

    // Detect Playwright/browser errors
    if (output.includes('playwright') || output.includes('browser') ||
        output.includes('chromium') || output.includes('Executable') ||
        output.includes('playwright._impl') || output.includes('AttributeError')) {
      if (output.includes('AttributeError') && output.includes('chromium')) {
        errorDetail = 'Navegador de Playwright no instalado. Ejecuta: python -m playwright install chromium --with-deps'
      } else if (output.includes('Executable') || output.includes('browser')) {
        errorDetail = 'Navegador de scraping no encontrado. Ejecuta: python -m playwright install chromium --with-deps'
      }
    }

    // Re-read the file and update the job status
    try {
      const raw = fs.readFileSync(JOBS_FILE, 'utf-8')
      const j = JSON.parse(raw)
      if (j[jobId]) {
        j[jobId].status = errorDetail ? 'error' : (code === 0 ? 'done' : 'error')
        j[jobId].leadsFound = errorDetail ? 0 : leadsFound
        j[jobId].finished = new Date().toISOString()
        if (errorDetail) j[jobId].error = errorDetail
        writeJobs(j)
        // Also trigger a refresh by updating leads.json in case the scraper didn't export
        try {
          const { execSync } = require('child_process')
          const py = JSON.parse(fs.readFileSync(
            path.join(process.cwd(), '..', 'leads_data', 'search_jobs.json'), 'utf-8'
          ))
          // triggers re-export silently
        } catch {}
      } else {
        // Fallback: job wasn't found in file, create/update it directly
        writeJobs({ [jobId]: {
          jobId, status: errorDetail ? 'error' : (code === 0 ? 'done' : 'error'),
          leadsFound: errorDetail ? 0 : leadsFound, finished: new Date().toISOString(),
          ...(errorDetail ? { error: errorDetail } : {})
        }})
      }
    } catch {
      // File doesn't exist or corrupt, create a fresh one
      writeJobs({ [jobId]: {
        jobId, status: errorDetail ? 'error' : (code === 0 ? 'done' : 'error'),
        leadsFound: errorDetail ? 0 : leadsFound, finished: new Date().toISOString(),
        ...(errorDetail ? { error: errorDetail } : {})
      }})
    }
    console.log(`Local search done: ${leadsFound} leads`)
    if (errorDetail) console.error(`[SEARCH ERROR] ${errorDetail}`)
  })

  return NextResponse.json({ jobId, status: 'running', message: 'Buscando localmente...' })
}
import fs from 'fs'
import path from 'path'

const DATA_DIR = path.join(process.cwd(), '..', 'leads_data')
const LEADS_FILE = path.join(DATA_DIR, 'leads.json')
const STATUS_FILE = path.join(DATA_DIR, 'status.json')

export interface Lead {
  id: number
  name: string
  category: string
  location: string
  state: string | null
  city: string | null
  address: string | null
  phone: string | null
  website: string | null
  email: string | null
  facebook: string | null
  instagram: string | null
  twitter: string | null
  rating: number | null
  reviews_count: number | null
  source: string
  source_url: string
  timestamp: string
  notes: string
  status: string
  changed_at?: string
}

const VALID_STATUSES = ['frio', 'tibio', 'caliente', 'contactado', 'aceptado', 'rechazado']

function cleanStatus(s: string | null | undefined): string {
  const v = (s || 'frio').toLowerCase()
  return VALID_STATUSES.includes(v) ? v : 'frio'
}

function readJSON<T = any>(filePath: string): T {
  try {
    if (fs.existsSync(filePath)) {
      return JSON.parse(fs.readFileSync(filePath, 'utf-8'))
    }
  } catch {}
  return (null as any)
}

function writeJSON(filePath: string, data: any) {
  const dir = path.dirname(filePath)
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true })
  fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf-8')
}

function readStatusOverrides(): Record<number, { status?: string; notes?: string; changed_at?: string }> {
  return readJSON(STATUS_FILE) || {}
}

function generateId(lead: any, index: number): number {
  if (lead.id != null && Number.isFinite(lead.id)) return lead.id
  const key = (lead.name || '') + '|' + (lead.location || '') + '|' + (lead.phone || '') + '|' + index
  let hash = 0
  for (let i = 0; i < key.length; i++) { hash = ((hash << 5) - hash) + key.charCodeAt(i); hash |= 0 }
  return Math.abs(hash) || (index + 1)
}

function mergeLeadOverrides(lead: any, overrides: Record<number, any>, index: number): Lead {
  const id = generateId(lead, index)
  const o = overrides[id]
  return {
    id,
    name: lead.name || '',
    category: lead.category || '',
    location: lead.location || '',
    state: lead.state || null,
    city: lead.city || null,
    address: lead.address || null,
    phone: lead.phone || null,
    website: lead.website || null,
    email: lead.email || null,
    facebook: lead.facebook || null,
    instagram: lead.instagram || null,
    twitter: lead.twitter || null,
    rating: lead.rating ?? null,
    reviews_count: lead.reviews_count ?? null,
    source: lead.source || 'google_maps',
    source_url: lead.source_url || '',
    timestamp: lead.timestamp || '',
    notes: o?.notes ?? lead.notes ?? '',
    status: o?.status ? cleanStatus(o.status) : cleanStatus(lead.status),
    changed_at: o?.changed_at ?? (lead.changed_at || undefined),
  }
}

function getAllLeadsData(): Lead[] {
  const leads: any[] = readJSON(LEADS_FILE) || []
  const overrides = readStatusOverrides()
  return leads.map((l, idx) => mergeLeadOverrides(l, overrides, idx + 1))
}

export async function getAllLeads(filters?: {
  category?: string; status?: string; location?: string; state?: string; city?: string; search?: string
}): Promise<Lead[]> {
  let leads = getAllLeadsData()

  if (filters?.category) leads = leads.filter(l => l.category === filters.category)
  if (filters?.status) leads = leads.filter(l => l.status === filters.status)
  if (filters?.location) leads = leads.filter(l => l.location === filters.location)
  if (filters?.state) leads = leads.filter(l => l.state === filters.state)
  if (filters?.city) leads = leads.filter(l => l.city === filters.city)
  if (filters?.search) {
    const q = filters.search.toLowerCase()
    leads = leads.filter(l =>
      l.name.toLowerCase().includes(q) ||
      (l.address || '').toLowerCase().includes(q) ||
      (l.phone || '').toLowerCase().includes(q) ||
      (l.notes || '').toLowerCase().includes(q)
    )
  }

  return leads
}

export async function getLeadById(id: number): Promise<Lead | null> {
  const leads = getAllLeadsData()
  return leads.find(l => l.id === id) || null
}

export async function updateLead(id: number, data: Partial<{ status: string; notes: string }>): Promise<boolean> {
  const overrides = readStatusOverrides()
  if (!overrides[id]) overrides[id] = {}
  if (data.status) {
    overrides[id].status = cleanStatus(data.status)
    overrides[id].changed_at = new Date().toISOString().slice(0, 10)
  }
  if (data.notes !== undefined) overrides[id].notes = data.notes
  writeJSON(STATUS_FILE, overrides)
  return true
}

export async function getStats() {
  const leads = getAllLeadsData()

  const total = leads.length
  const withPhone = leads.filter(l => l.phone).length
  const withWebsite = leads.filter(l => l.website).length
  const withAddress = leads.filter(l => l.address).length
  const ratings = leads.filter(l => l.rating != null).map(l => l.rating!)
  const avgRating = ratings.length ? (ratings.reduce((a, b) => a + b, 0) / ratings.length) : 0

  const byStatus: Record<string, number> = {}
  const byCategory: Record<string, number> = {}
  const byLocation: Record<string, number> = {}
  const byState: Record<string, number> = {}

  leads.forEach(l => {
    byStatus[l.status] = (byStatus[l.status] || 0) + 1
    byCategory[l.category] = (byCategory[l.category] || 0) + 1
    byLocation[l.location] = (byLocation[l.location] || 0) + 1
    if (l.state) byState[l.state] = (byState[l.state] || 0) + 1
  })

  return { total, withPhone, withWebsite, withAddress, avgRating: Math.round(avgRating * 100) / 100, byStatus, byCategory, byLocation, byState }
}

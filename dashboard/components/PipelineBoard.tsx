'use client'

import { Lead } from '@/lib/data'
import { useState, useCallback, useRef } from 'react'

const COLUMNS = [
  { key: 'frio', label: 'Frio', color: 'border-blue-400 bg-blue-50' },
  { key: 'tibio', label: 'Tibio', color: 'border-amber-400 bg-amber-50' },
  { key: 'caliente', label: 'Caliente', color: 'border-red-400 bg-red-50' },
  { key: 'contactado', label: 'Contactado', color: 'border-purple-400 bg-purple-50' },
  { key: 'aceptado', label: 'Aceptado', color: 'border-green-400 bg-green-50' },
]

interface Props {
  leads: Lead[]
  onStatusChange: (id: number, status: string) => void
}

export default function PipelineBoard({ leads, onStatusChange }: Props) {
  const dragIdRef = useRef<number | null>(null)
  const [justDropped, setJustDropped] = useState<number | null>(null)

  const grouped: Record<string, Lead[]> = {}
  COLUMNS.forEach(c => { grouped[c.key] = [] })
  leads.forEach(l => {
    if (grouped[l.status]) grouped[l.status].push(l)
  })

  const handleDragStart = useCallback((e: React.DragEvent, leadId: number) => {
    dragIdRef.current = leadId
    e.dataTransfer.effectAllowed = 'move'
    e.dataTransfer.setData('text/plain', String(leadId))
    const el = e.currentTarget as HTMLElement
    el.style.opacity = '0.4'
    el.style.transform = 'scale(0.95)'
  }, [])

  const handleDragEnd = useCallback((e: React.DragEvent) => {
    document.querySelectorAll('[data-col]').forEach(el => {
      const h = el as HTMLElement
      h.style.removeProperty('outline')
      h.style.removeProperty('outline-offset')
    })
    const el = e.currentTarget as HTMLElement
    el.style.opacity = '1'
    el.style.transform = ''
    dragIdRef.current = null
  }, [])

  const clearOutlines = useCallback(() => {
    document.querySelectorAll('[data-col]').forEach(el => {
      const h = el as HTMLElement;
      (h.style as any).outline = ''
      ;(h.style as any)['outline-offset'] = ''
    })
  }, [])

  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault()
    const col = (e.currentTarget as HTMLElement).closest('[data-col]') as HTMLElement | null
    if (col) {
      clearOutlines()
      ;(col.style as any).outline = '3px solid #3b82f6'
      ;(col.style as any)['outline-offset'] = '-3px'
    }
  }, [clearOutlines])

  const handleDragLeaveCol = useCallback((e: React.DragEvent) => {
    const col = (e.currentTarget as HTMLElement).closest('[data-col]') as HTMLElement | null
    if (col) {
      ;(col.style as any).outline = ''
      ;(col.style as any)['outline-offset'] = ''
    }
  }, [])

  const handleDrop = useCallback((e: React.DragEvent, columnKey: string) => {
    e.preventDefault()
    e.stopPropagation()
    clearOutlines()
    const leadId = parseInt(e.dataTransfer.getData('text/plain')) || dragIdRef.current
    if (leadId && columnKey) {
      onStatusChange(leadId, columnKey)
      setJustDropped(leadId)
      setTimeout(() => setJustDropped(null), 400)
    }
    dragIdRef.current = null
  }, [onStatusChange])

  const handleColumnClick = useCallback((leadId: number) => {
    const s = window.prompt('Nuevo estado: frio, tibio, caliente, contactado, aceptado, rechazado')
    if (s && COLUMNS.some(c => c.key === s.toLowerCase())) {
      onStatusChange(leadId, s.toLowerCase())
    }
  }, [onStatusChange])

  return (
    <div className="section-enter">
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-lg font-bold text-gray-800">Pipeline de Leads</h2>
        <span className="text-xs text-gray-400">Arrastra tarjetas entre columnas o haz clic para cambiar estado</span>
      </div>
      <div className="grid grid-cols-5 gap-3 min-h-[400px]">
        {COLUMNS.map(col => (
          <div
            key={col.key}
            data-col={col.key}
            onDragOver={handleDragOver}
            onDragLeave={handleDragLeaveCol}
            onDrop={(e) => handleDrop(e, col.key)}
            className={`rounded-xl border-t-4 ${col.color} flex flex-col p-3 transition-shadow duration-200`}
          >
            <div className="flex items-center justify-between mb-3">
              <span className="text-sm font-semibold text-gray-700">{col.label}</span>
              <span className="text-xs font-medium text-gray-400 bg-white/60 px-2 py-0.5 rounded-full">
                {grouped[col.key].length}
              </span>
            </div>
            <div className="flex-1 space-y-2 overflow-y-auto max-h-[500px] min-h-[200px]">
              {grouped[col.key].map(l => (
                <div
                  key={l.id}
                  draggable
                  onDragStart={(e) => handleDragStart(e, l.id)}
                  onDragEnd={handleDragEnd}
                  onClick={() => handleColumnClick(l.id)}
                  className={`bg-white rounded-lg border border-gray-200 px-3 py-2.5 cursor-grab active:cursor-grabbing card-hover transition-all duration-150 ${
                    justDropped === l.id ? 'card-drop' : ''
                  }`}
                >
                  <div className="font-medium text-sm text-gray-800 truncate">{l.name}</div>
                  <div className="flex items-center gap-2 mt-1">
                    {l.rating && <span className="text-xs text-amber-500">★ {l.rating}</span>}
                    {l.category && <span className="text-xs text-gray-400 truncate">{l.category}</span>}
                  </div>
                  <div className="flex items-center gap-1 mt-1.5">
                    {l.city && <span className="text-[10px] text-gray-400">{l.city}</span>}
                    {l.phone && <span className="text-[10px] text-green-500 ml-auto">{l.phone}</span>}
                  </div>
                </div>
              ))}
              {grouped[col.key].length === 0 && (
                <div className="text-xs text-gray-300 text-center py-8 border-2 border-dashed border-gray-200 rounded-lg pointer-events-none">
                  Arrastra leads aqui
                </div>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}

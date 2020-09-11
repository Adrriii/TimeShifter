LOGGING = false
VERBOSE = false

last_sts = {}
last_sbs = {}

logs_arr = {}

function draw()
    bpmlist()

    if LOGGING then
        logs()
    end
end

function get(identifier, defaultValue)
    return state.GetValue(identifier) or defaultValue
end

function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

function bpmlist()
    imgui.Begin("TimeShifter")

    apply = imgui.Button("Apply")

    bpmid = 1

    for _,bpminfo in pairs(map.TimingPoints) do
        bpm = {}
        bpm.EndTime = bpminfo.StartTime + map.GetTimingPointLength(bpminfo)
        bpm.StartTime = bpminfo.StartTime
        bpm.Bpm = bpminfo.Bpm
        bpm.obj = bpminfo

        last_sts[bpmid] = round(bpminfo.StartTime)
        last_sbs[bpmid] = bpminfo.Bpm

        bpmPoint(bpm)
        bpmid = bpmid + 1
    end
    
    imgui.Text("OK")
    imgui.End()
end

function bpmPoint(bpm)
    imgui.Text("BPM Point #"..bpmid)

    local st = get("st"..bpmid, round(bpm.StartTime))
    _, st = imgui.InputInt("Time# #"..bpmid, st)
    state.SetValue("st"..bpmid,st)

    local notes = {}

    if apply then
        for _,note in pairs(map.HitObjects) do
            if note.StartTime >= bpm.StartTime and note.StartTime <= bpm.EndTime then
                table.insert(notes, note)
            end
        end

        imgui.Text("Calc")
    end

    if apply and last_sts[bpmid] ~= st then
        handleTimeChange(notes, bpm, last_sts[bpmid], st)
        last_sts[bpmid] = st
    end

    local sb = get("sb"..bpmid, round(bpm.Bpm,2))
    _, sb = imgui.InputFloat("BPM# #"..bpmid, sb, 0.01,0.01,"%.2f")
    state.SetValue("sb"..bpmid,sb)

    if apply and last_sbs[bpmid] ~= sb then
        handleBpmChange(notes, bpm, last_sbs[bpmid], sb)
        last_sbs[bpmid] = sb
    end
     
end

function handleTimeChange(notes, bpm, old, new)
    local diff = (new - old)

    local newhits = {}
    log("Processing offset change: "..old.." -> "..new..".")
    c = 0
    for _,note in pairs(notes) do
        c = c + 1
        log_verbose("Note "..c.." "..note.StartTime.."-"..note.EndTime.." ("..utils.MillisecondsToTime(note.StartTime)..") ["..note.Lane.."]")
        local endtime = note.EndTime

        if endtime ~= 0 then
            if endtime < bpm.EndTime then
                endtime = endtime + diff
            end
        end

        table.insert(newhits,utils.CreateHitObject(note.StartTime + diff, note.Lane, endtime, note.HitSound))
    end
    log("Processing done. Applying changes.")

    actions.ChangeTimingPointOffset(bpm.obj, new)
    actions.RemoveHitObjectBatch(notes)
    actions.PlaceHitObjectBatch(newhits)
end

function handleBpmChange(notes, bpm, old, new)

    local newhits = {}
    local ratio = old / new

    log("Processing BPM Change: "..old.." -> "..new)
    c = 0
    for _,note in pairs(notes) do
        c = c + 1
        log_verbose("Note "..c.." "..note.StartTime.."-"..note.EndTime.." ("..utils.MillisecondsToTime(note.StartTime)..") ["..note.Lane.."]")
        local endtime = note.EndTime

        if endtime ~= 0 then
            if endtime < bpm.EndTime then
                local diste1 = (note.EndTime - bpm.StartTime)
                local diste2 = diste1 * ratio
                endtime = bpm.StartTime + diste2
            end
        end

        local dist1 = (note.StartTime - bpm.StartTime)
        local dist2 = dist1 * ratio
        table.insert(newhits,utils.CreateHitObject(round(bpm.StartTime + dist2), note.Lane, endtime, note.HitSound))
    end
    log("Processing done. Applying changes.")

    actions.ChangeTimingPointBpm(bpm.obj, new)
    actions.RemoveHitObjectBatch(notes)
    actions.PlaceHitObjectBatch(newhits)
end

function log(text)
    if LOGGING then
        table.insert(logs_arr,text)
    end
end

function log_verbose(text)
    if VERBOSE then
        table.insert(logs_arr,text)
    end
end

function logs()
    imgui.Begin("TimeShifter Logs")

    for _,log in pairs(logs_arr) do
        imgui.Text(log)
    end
    imgui.End()
end
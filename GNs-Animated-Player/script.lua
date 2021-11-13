
--========================================================--
--GNs animated player by GNamimates
--version 1.1
--adds cool animations using the one and only figura mod!
--========================================================--


PI = 3.14159

attackKey = keybind.getRegisteredKeybind("key.attack")
interactKey = keybind.getRegisteredKeybind("key.use")
dropKey = keybind.getRegisteredKeybind("key.drop")

--======CONFIG=======--
-- I don suggest changing this one, because it can break the punching animation
stiffness = 0.3 --the lower the value is, the smoother the blending between animation tracks is

--note: dosent have to be the full name of the item, just a key word of it
-- items with the word in their name wont have the punching animation be played on click
noPunchItems = {"bow","sword","shield","trident"}
--climbable blocks
climbableBlocks = {"vine","ladder","scaffolding"}

--animation prioritization owo (the higher the number is, the more prioritized it is)
--1. idle                 |
--2. sneaking             |
--3. sprinting            |
--4. walking              |
--5. flying               |
--6. climbing             |
--7. idle swimming        |
--8. sprint swimming      |
--9. punching animations  |(startup, cooldown, cooldown-ier)
--10.special item holding|(bow, shield, <item> on a stick, sword(all types))
--11.conditional attacks  |(sword)


--=====STARTUP STUFF=====--
function player_init()
    lastgrounded = false--used to simulate AI advance techology in humanity called "skipping"
    distWalked = 0.0 --used for the walking animation
    veldist = 0 --stands for "velocity distance" only for x and z tho
    altitudeClimbed = 0 -- used for climbing animation tracks
    lastPunch = 100 --the time since last punch
    HandMoved = true --its for something, idk

    lastArmUsed = false --false = right | true = left | purely cosmetic stuff
    lastPos = player.getPos()

    --hides the victim >:)
    for key, value in pairs(vanilla_model) do
        value.setEnabled(false)    
    end
    for key, value in pairs(armor_model) do
        value.setEnabled(false)    
    end
    --used to blend between animation tracks
    pose = {
        head={0,0,0},
        body={0,0,0},

        armLeft={0,0,0},
        armRight={0,0,0},

        legLeft={0,0,0},
        legRight={0,0,0},

        handLeft={0,0,0},
        handRight={0,0,0},

        footleft={0,0,0},
        footRight={0,0,0} 
    }
end

--===== ANIMATIONS N STUFF=====--
function tick()
    local isSprinting = false
    local isClimbing = false

    time = world.getTime()
    lastPunch = lastPunch + 1

    local velocity = (player.getPos()-lastPos)*0.52
    localVel = {
        x=(math.sin(math.rad(-player.getRot().y))*velocity.x)+(math.cos(math.rad(-player.getRot().y))*velocity.z),
        0,
        z=(math.sin(math.rad(-player.getRot().y+90))*velocity.x)+(math.cos(math.rad(-player.getRot().y+90))*velocity.z)
    }
    local moveMult = math.max(math.min(veldist*10,1),0)
    veldist = (lenth2({x=velocity.x,y=velocity.z}))
    altitudeClimbed = altitudeClimbed + velocity.y

    --sprintDetection
    if player.isWet() then
        isSprinting = (player.getAnimation() == "SWIMMING")
    else
        if veldist > 0.14 then
            isSprinting = true
        end
    end
    --climbable block detection
    local tempPpos = {player.getPos().x,player.getPos().y,player.getPos().z}
    tempPpos[2] = tempPpos[2] + 0.9
    for I in pairs(climbableBlocks) do
        if string.find(tostring(world.getBlockState(vectors.of(tempPpos)).name),climbableBlocks[I]) then
            isClimbing = true
            
        end
    end    

    if player.isGrounded() ~= lastgrounded then--triggers once is grounded or not
        lastgrounded = player.isGrounded()--UPDATE: idk what is this for, but might be useful for the future
        distWalked = distWalked + (PI*0.4)--added skipping
    end


    --animation
    -- the poggers part \#o-o#/
    
    if player.isGrounded() or player.isWet() then
        distWalked = distWalked + (veldist*3)
    end

    if not player.isWet() then
        if player.isGrounded() then
            
            if veldist < 0.1 then--idle animation
                pose.head = {0,0,0}
                pose.legLeft = {0,0,0}
                pose.footleft = {0,0,0}
                pose.legRight = {0,0,0}
                pose.footRight = {0,0,0}
                pose.body = {0,0,0}
                model.Body.setPos({0,0,0}) 
                model.Body.LeftArm.setPos({0,0,0})
                pose.armLeft = {math.cos(time*0.1)*2-1,0,math.sin(time*0.1)*5-2.5}
                pose.armRight = {-math.cos(time*0.1)*2+1,0,-math.sin(time*0.1)*5+2.5}
                pose.handLeft = {0,0,0}
                pose.handRight = {0,0,0}
            end
            if player.isSneaky() then
                --sneaking animation track
                pose.head = {30,0,0}
                pose.legLeft = {(math.sin(distWalked)*120+15)*moveMult+30,0,0}
                pose.footleft = {(math.sin(distWalked+math.rad(-(90*dotp(localVel.x+0.01))))*(45)-45)*moveMult,0,0}
                pose.legRight = {(math.sin(distWalked)*(-120+15))*moveMult+30,0,0}
                pose.footRight = {(math.sin(distWalked+math.rad(-(90*dotp(localVel.x+0.01))))*-45-45)*moveMult,0,0}
                pose.body = {localVel.x*-50-30,math.sin(distWalked)*-10,localVel.z*70}
                model.Body.setPos({0,math.abs(math.sin(distWalked)),0})
                pose.armLeft = {math.sin(distWalked)*-45*moveMult,0,0}
                pose.armRight = {math.sin(distWalked)*45*moveMult,0,0}
                pose.handLeft = {(math.sin(distWalked-1)*-22.5+25)*moveMult,0,0}
                pose.handRight = {(math.sin(distWalked-1)*22.5+25)*moveMult,0,0}
            else
                if veldist > 0.01 then
                    if isSprinting and dotp(localVel.x) > 0 then
                        -- sprinting animation track
                        pose.head = {20,0,0}
                        pose.legLeft = {(math.sin(distWalked)*80+20)*moveMult,0,-5}
                        pose.footleft = {(math.sin(distWalked+math.rad(-(90*dotp(localVel.x+0.01))))*(45)-45)*moveMult,0,0}
                        pose.legRight = {(math.sin(distWalked)*-80+20)*moveMult,0,5}
                        pose.footRight = {(math.sin(distWalked+math.rad(-(90*dotp(localVel.x+0.01))))*-45-45)*moveMult,0,0}
                        pose.body = {localVel.x*-50-20,math.sin(distWalked)*5,localVel.z*70}
                        model.Body.setPos({0,-math.abs(math.sin(distWalked)),0})
                        pose.armLeft = {math.sin(distWalked)*-45*moveMult,0,-20}
                        pose.armRight = {math.sin(distWalked)*45*moveMult,0,20}
                        pose.handLeft = {(math.sin(distWalked-1)*-22.5+25)*moveMult,0,0}
                        pose.handRight = {(math.sin(distWalked-1)*22.5+25)*moveMult,0,0}
                    else
                        --walking animation track
                        pose.head = {0,0,0}
                        pose.legLeft = {(math.sin(distWalked)*50+15)*moveMult,0,0}
                        pose.footleft = {(math.sin(distWalked+math.rad(-(90*dotp(localVel.x+0.01))))*(45)-45)*moveMult,0,0}
                        pose.legRight = {(math.sin(distWalked)*(-50+15))*moveMult,0,0}
                        pose.footRight = {(math.sin(distWalked+math.rad(-(90*dotp(localVel.x+0.01))))*-45-45)*moveMult,0,0}
                        pose.body = {localVel.x*-50,math.sin(distWalked)*5,localVel.z*70}
                        model.Body.setPos({0,-math.abs(math.sin(distWalked))*moveMult,0})
                        pose.armLeft = {math.sin(distWalked)*-45*moveMult,0,0}
                        pose.armRight = {math.sin(distWalked)*45*moveMult,0,0}
                        pose.handLeft = {(math.sin(distWalked-1)*-22.5+25)*moveMult,0,0}
                        pose.handRight = {(math.sin(distWalked-1)*22.5+25)*moveMult,0,0}
                        end
                    end
            end
        else
            if isClimbing then
                --climbing animation track
                lastPunch = 100
                pose.head = {0,0,0}
                pose.body = {0,0,math.sin(altitudeClimbed*PI*2)}
                pose.legLeft = {-math.sin(altitudeClimbed*PI*2)*-60+60,math.cos(altitudeClimbed*PI*2)*22+22,0}
                pose.legRight = {-math.sin(altitudeClimbed*PI*2)*60+60,math.cos(altitudeClimbed*PI*2)*22-22,0}
                pose.footleft = {-math.sin(altitudeClimbed*PI*2)*60-60,0,0}
                pose.footRight = {-math.sin(altitudeClimbed*PI*2)*-60-60,0,0}
                pose.armLeft = {-math.sin(altitudeClimbed*PI*2)*90+90,-math.cos(altitudeClimbed*PI*2)*22+22,0}
                pose.armRight = {-math.sin(altitudeClimbed*PI*2)*-90+90,-math.cos(altitudeClimbed*PI*2)*22-22,0}
                pose.handLeft = {-math.sin(altitudeClimbed*PI*2)*-40+40,0,0}
                pose.handRight = {-math.sin(altitudeClimbed*PI*2)*40+40,0,0}
            else
            --flying animation track
                pose.head = {0,0,0}
                pose.body = {localVel.x*-50+math.min(velocity.y*-50,20),0,localVel.z*70}
                pose.legLeft = {dotp(math.max(math.sin(distWalked),0))*80,math.max(math.sin(distWalked),0)*15,0}
                pose.legRight = {dotp(math.max(-math.sin(distWalked),0))*80,math.max(-math.sin(distWalked),0)*-15,0}
                pose.footleft = {-dotp(math.max(math.sin(distWalked),0))*80-10,0,0}
                pose.footRight = {-dotp(math.max(-math.sin(distWalked),0))*80-10,0,0}
                pose.armLeft = {0,0,-60}
                pose.armRight = {0,0,60}
                pose.handLeft = {50,0,0}
                pose.handRight = {50,0,0}
            end
        end
    else
        if isSprinting then
            -- sprinting swimming animation track
            lastPunch = 100
            pose.head = {0,0,0}
            pose.body = {0,math.sin(distWalked)*10+math.sin(distWalked*2)*2.5,0}
            pose.legLeft = {math.sin(distWalked*2)*45+20,0,0}
            pose.legRight = {-math.sin(distWalked*2)*45+20,0,0}
            pose.footleft = {-math.cos(distWalked*2)*45-45,0,0}
            pose.footRight = {math.cos(distWalked*2)*45-45,0,0}
            pose.armLeft = {math.cos(distWalked*1)*40,0,math.sin(distWalked*1)*40-40}
            pose.armRight = {-math.cos(distWalked*1)*40,0,-math.sin(distWalked*1)*-40+40}
            pose.handLeft = {0,0,math.sin(distWalked*1)*40-40}
            pose.handRight = {0,0,math.sin(distWalked*-1)*-40+40}
            
        else
        -- slow swimming animation track
            pose.head = {0,0,0}
            pose.body = {localVel.x*-300,0,localVel.z*200}
            model.Body.setPos({0,-math.sin(time*0.2+2),0})

            pose.legLeft = {math.cos(time*0.2)*40,0,math.sin(time*0.2)*10-10}
            pose.legRight = {math.cos(time*0.2)*40,0,math.sin(time*0.2)*-10+10}
            pose.footleft = {math.sin(time*-0.2)*45-45,0,0}
            pose.footRight = {math.sin(time*-0.2)*45-45,0,0}
            pose.armLeft = {math.cos(time*0.2)*40,0,math.sin(time*0.2)*10-10}
            pose.armRight = {math.cos(time*0.2)*40,0,math.sin(time*0.2)*-10+10}
            pose.handLeft = {0,0,0}
            pose.handRight = {0,0,0}
        end
    end
    --other stuff
    

    --prioritized click events
    local canPunch = true
    for I in pairs(noPunchItems) do
        if string.find(player.getEquipmentItem(1).getType(),noPunchItems[I]) then
            canPunch = false
        end
    end
    --drop
    if dropKey.isPressed() then
        lastPunch = 0
        HandMoved = false
    end

    --punching poses
    if canPunch then
    if lastPunch < 60 then--cooling down arm
        pose.armRight[2] = 45 + pose.armRight[2]
        pose.armLeft[2] = -45 + pose.armLeft[2]
        pose.handLeft[1] = 20 + pose.handLeft[1]
        pose.handRight[1] = 20 + pose.handRight[1]
    end
        if HandMoved == false then--right punch
            if lastPunch < 20 then--retracting arm
                pose.armRight[1] = -model.Body.MIMIC_HEAD.getRot().x+90
                pose.armRight[2] = -45
                pose.handRight[1] = 0
                pose.body[2] = pose.body[2]+ 45
                pose.head[2] = pose.head[2] - 45
            end
        
        if lastPunch == 1 then--startup punch
            pose.armRight[1] = (-model.Body.MIMIC_HEAD.getRot().x+90)*2
            pose.armRight[2] = 180
            pose.armRight[2] = -45
            pose.handRight[1] = 0
            pose.body[2] = pose.body[2]+ 45
        end
        
        else--left hand punch
            if lastPunch < 20 then--retracting arm
                pose.armLeft[1] = -model.Body.MIMIC_HEAD.getRot().x+90
                pose.armLeft[2] = 45
                pose.handLeft[1] = 0
                pose.body[2] = pose.body[2]- 45
                pose.head[2] = pose.head[2] + 45
            end
        
            if lastPunch == 1 then--startup punch
                pose.armLeft[1] = (-model.Body.MIMIC_HEAD.getRot().x+90)*2
                pose.armLeft[2] = 180
                pose.armLeft[2] = 45
                pose.handLeft[1] = 0
                pose.body[2] = pose.body[2]- 45
            end
        end
    end
    --special poses | idle
    if player.getEquipmentItem(1).getType() == "minecraft:shield" then
        pose.armRight[1] = pose.armRight[1]+ 15
        pose.armRight[2] = pose.armRight[2]+ 45
        pose.handRight[1] = pose.handRight[1]+ 15
    end
    if string.find(player.getEquipmentItem(1).getType(),"sword") then
        pose.armRight[1] = pose.armRight[1]+ 15
        pose.armRight[2] = pose.armRight[2]+ -15
        pose.handRight[1] = pose.handRight[1]+ 15
    end
    if string.find(player.getEquipmentItem(1).getType(),"on_a_stick") then
        pose.armRight[1] = pose.armRight[1]+ 43
        pose.armRight[2] = pose.armRight[2]+ 15
        pose.handRight[1] = pose.handRight[1]+ 15
    end
    if string.find(player.getEquipmentItem(1).getType(),"bow") then
        pose.armRight = {-model.Body.MIMIC_HEAD.getRot().x+90,-model.Body.MIMIC_HEAD.getRot().y,0}
        pose.handRight = {5,0,0}
        pose.armLeft = {-model.Body.MIMIC_HEAD.getRot().x+90,-model.Body.MIMIC_HEAD.getRot().y-45,0}
        pose.handLeft = {5,0,0}
    end
    

    --special poses | attack
    if attackKey.isPressed() then
        if lastPunch > 3 then
            --clicked
            lastPunch = 0
            if HandMoved then
                HandMoved = false
            else
                HandMoved = true
            end
            if string.find(player.getEquipmentItem(1).getType(),"sword") then
                pose.armRight[2] = 100
                pose.handRight[1] = pose.handRight[1]+ 15
                pose.body[2] = pose.body[2]+ 100
                pose.head[2] = pose.head[2]+ -100
            end
            if string.find(player.getEquipmentItem(1).getType(),"shovel") then
                pose.armRight[2] = 400
                pose.handRight[1] = pose.handRight[1]+ 15
                pose.body[2] = pose.body[2]+ 100
                pose.head[2] = pose.head[2]+ -100
            end
        end
    end
    -- special poses | interact
    if interactKey.isPressed() then
        if player.getEquipmentItem(1).getType() == "minecraft:shield" then
            pose.armRight[2] = -model.Body.MIMIC_HEAD.getRot().y+30
            pose.handRight[1] = -model.Body.MIMIC_HEAD.getRot().x+30 
        else
            pose.armRight[2] = -model.Body.MIMIC_HEAD.getRot().y
            pose.armRight[1] = -model.Body.MIMIC_HEAD.getRot().x+90
        end
    end
    lastPos = player.getPos()
end

function render(delta)
    -- mode model.MIMIC_RIGHT_ARM_fps.setEnabled(renderer.isFirstPerson()) dosent work for some reason...
    if renderer.isFirstPerson() then
        model.MIMIC_RIGHT_ARM_fps.setEnabled(true)
    else
        model.MIMIC_RIGHT_ARM_fps.setEnabled(false)
    end
    
    --interpiolate pose to model
    model.Body.MIMIC_HEAD.offset.setRot(tableLerp(model.Body.MIMIC_HEAD.offset.getRot(),pose.head,stiffness))
    model.Body.setRot(tableLerp(model.Body.getRot(),pose.body,stiffness))
    
    model.Body.LeftArm.setRot(tableLerp(model.Body.LeftArm.getRot(),pose.armLeft,stiffness))
    model.Body.RightArm.setRot(tableLerp(model.Body.RightArm.getRot(),pose.armRight,stiffness))

    model.Body.LeftLeg.setRot(tableLerp(model.Body.LeftLeg.getRot(),pose.legLeft,stiffness))
    model.Body.RightLeg.setRot(tableLerp(model.Body.RightLeg.getRot(),pose.legRight,stiffness))

    model.Body.LeftLeg.LeftFoot.setRot(tableLerp(model.Body.LeftLeg.LeftFoot.getRot(),pose.footleft,stiffness))
    model.Body.RightLeg.RightFoot.setRot(tableLerp(model.Body.RightLeg.RightFoot.getRot(),pose.footRight,stiffness))

    model.Body.LeftArm.LeftHand.setRot(tableLerp(model.Body.LeftArm.LeftHand.getRot(),pose.handLeft,stiffness))
    model.Body.RightArm.RightHand.setRot(tableLerp(model.Body.RightArm.RightHand.getRot(),pose.handRight,stiffness))
end


--the "im too dumb to find them so I made my own" section
function lenth3(vector)
    return math.sqrt(math.pow((vector.x),2)+math.pow((vector.y),2)+math.pow((vector.x),2))
end

function lenth2(vector)
    return math.sqrt(math.pow((vector.x),2)+math.pow((vector.y),2))
end

function dotp(value)
    if value ~= 0 then
        return value/math.abs(value)
    end
    return 0
end

--things I borrowed
function lerp(a, b, x)
    return a + (b - a) * x
end

function tableLerp(a, b, x)
    return {lerp(a[1],b[1],x),lerp(a[2],b[2],x),lerp(a[3],b[3],x)}
end
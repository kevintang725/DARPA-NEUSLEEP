#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
This experiment was created using PsychoPy3 Experiment Builder (v3.0.1),
    on June 13, 2025, at 08:56
If you publish work using this script please cite the PsychoPy publications:
    Peirce, JW (2007) PsychoPy - Psychophysics software in Python.
        Journal of Neuroscience Methods, 162(1-2), 8-13.
    Peirce, JW (2009) Generating stimuli for neuroscience using PsychoPy.
        Frontiers in Neuroinformatics, 2:10. doi: 10.3389/neuro.11.010.2008
"""

from __future__ import absolute_import, division
from psychopy import locale_setup, sound, gui, visual, core, data, event, logging, clock
from psychopy.constants import (NOT_STARTED, STARTED, PLAYING, PAUSED,
                                STOPPED, FINISHED, PRESSED, RELEASED, FOREVER)
import numpy as np  # whole numpy lib is available, prepend 'np.'
from numpy import (sin, cos, tan, log, log10, pi, average,
                   sqrt, std, deg2rad, rad2deg, linspace, asarray)
from numpy.random import random, randint, normal, shuffle
import os  # handy system and path functions
import sys  # to get file system encoding


# Ensure that relative paths start from the same directory as this script
_thisDir = os.path.dirname(os.path.abspath(__file__))
os.chdir(_thisDir)

# Store info about the experiment session
psychopyVersion = '3.0.1'
expName = 'HaririTask_Ver1'  # from the Builder filename that created this script
expInfo = {'participant': '', 'session': '001'}
dlg = gui.DlgFromDict(dictionary=expInfo, title=expName)
if dlg.OK == False:
    core.quit()  # user pressed cancel
expInfo['date'] = data.getDateStr()  # add a simple timestamp
expInfo['expName'] = expName
expInfo['psychopyVersion'] = psychopyVersion

# Data file name stem = absolute path + name; later add .psyexp, .csv, .log, etc
filename = _thisDir + os.sep + u'data/%s_%s_%s' % (expInfo['participant'], expName, expInfo['date'])

# An ExperimentHandler isn't essential but helps with data saving
thisExp = data.ExperimentHandler(name=expName, version='',
    extraInfo=expInfo, runtimeInfo=None,
    originPath='C:\\Users\\local.BME\\Desktop\\HaririTask\\HaririTask_Ver1_lastrun.py',
    savePickle=True, saveWideText=True,
    dataFileName=filename)
# save a log file for detail verbose info
logFile = logging.LogFile(filename+'.log', level=logging.DEBUG)
logging.console.setLevel(logging.WARNING)  # this outputs to the screen, not a file

endExpNow = False  # flag for 'escape' or other condition => quit the exp

# Start Code - component code to be run before the window creation

# Setup the Window
win = visual.Window(
    size=[1280, 720], fullscr=True, screen=0,
    allowGUI=False, allowStencil=False,
    monitor='testMonitor', color=[1.000,1.000,1.000], colorSpace='rgb',
    blendMode='avg', useFBO=True)
# store frame rate of monitor if we can measure it
expInfo['frameRate'] = win.getActualFrameRate()
if expInfo['frameRate'] != None:
    frameDur = 1.0 / round(expInfo['frameRate'])
else:
    frameDur = 1.0 / 60.0  # could not measure, so guess

# Initialize components for Routine "PleaseWait"
PleaseWaitClock = core.Clock()
PleaseWaitText = visual.TextStim(win=win, name='PleaseWaitText',
    text='Please wait...\n\nTask will begin shortly.',
    font='Arial',
    pos=(0, 0), height=0.15, wrapWidth=None, ori=0, 
    color='black', colorSpace='rgb', opacity=1, 
    languageStyle='LTR',
    depth=0.0);

# Initialize components for Routine "BeginningFixation"
BeginningFixationClock = core.Clock()

BeginningFixationCross = visual.ImageStim(
    win=win, name='BeginningFixationCross',
    image='C:\\Users\\local.BME\\Desktop\\HaririTask\\stimuli\\Fixation.bmp', mask=None,
    ori=0, pos=(0, 0), size=(0.85, 1),
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    texRes=128, interpolate=True, depth=-1.0)

# Initialize components for Routine "trial"
trialClock = core.Clock()


TopImage = visual.ImageStim(
    win=win, name='TopImage',
    image='sin', mask=None,
    ori=0, pos=(0, 0.5), size=(0.35, 0.75),
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    texRes=128, interpolate=True, depth=-2.0)
LeftFrame = visual.ImageStim(
    win=win, name='LeftFrame',
    image='sin', mask=None,
    ori=0, pos=(-0.5, -0.5), size=(0.38, 0.78),
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    texRes=128, interpolate=True, depth=-3.0)
LeftImage = visual.ImageStim(
    win=win, name='LeftImage',
    image='sin', mask=None,
    ori=0, pos=(-0.5, -0.5), size=(0.35, 0.75),
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    texRes=128, interpolate=True, depth=-4.0)
RightFrame = visual.ImageStim(
    win=win, name='RightFrame',
    image='sin', mask=None,
    ori=0, pos=(0.5, -0.5), size=(0.38, 0.78),
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    texRes=128, interpolate=True, depth=-5.0)
RightImage = visual.ImageStim(
    win=win, name='RightImage',
    image='sin', mask=None,
    ori=0, pos=(0.5, -0.5), size=(0.35, 0.75),
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    texRes=128, interpolate=True, depth=-6.0)

TrialFixationEnd = visual.ImageStim(
    win=win, name='TrialFixationEnd',
    image='C:\\Users\\local.BME\\Desktop\\HaririTask\\stimuli\\Fixation.bmp', mask=None,
    ori=0, pos=(0, 0), size=(0.85, 1),
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    texRes=128, interpolate=True, depth=-9.0)


# Initialize components for Routine "EndingFixation"
EndingFixationClock = core.Clock()

EndingFixationCross = visual.ImageStim(
    win=win, name='EndingFixationCross',
    image='C:\\Users\\local.BME\\Desktop\\HaririTask\\stimuli\\Fixation.bmp', mask=None,
    ori=0, pos=(0, 0), size=(0.85, 1),
    color=[1,1,1], colorSpace='rgb', opacity=1,
    flipHoriz=False, flipVert=False,
    texRes=128, interpolate=True, depth=-1.0)


# Create some handy timers
globalClock = core.Clock()  # to track the time since experiment started
routineTimer = core.CountdownTimer()  # to track time remaining of each (non-slip) routine 

# ------Prepare to start Routine "PleaseWait"-------
t = 0
PleaseWaitClock.reset()  # clock
frameN = -1
continueRoutine = True
# update component parameters for each repeat
key_resp_starttask = event.BuilderKeyResponse()
# keep track of which components have finished
PleaseWaitComponents = [PleaseWaitText, key_resp_starttask]
for thisComponent in PleaseWaitComponents:
    if hasattr(thisComponent, 'status'):
        thisComponent.status = NOT_STARTED

# -------Start Routine "PleaseWait"-------
while continueRoutine:
    # get current time
    t = PleaseWaitClock.getTime()
    frameN = frameN + 1  # number of completed frames (so 0 is the first frame)
    # update/draw components on each frame
    
    # *PleaseWaitText* updates
    if t >= 0.0 and PleaseWaitText.status == NOT_STARTED:
        # keep track of start time/frame for later
        PleaseWaitText.tStart = t
        PleaseWaitText.frameNStart = frameN  # exact frame index
        PleaseWaitText.setAutoDraw(True)
    
    # *key_resp_starttask* updates
    if t >= 0.0 and key_resp_starttask.status == NOT_STARTED:
        # keep track of start time/frame for later
        key_resp_starttask.tStart = t
        key_resp_starttask.frameNStart = frameN  # exact frame index
        key_resp_starttask.status = STARTED
        # keyboard checking is just starting
        win.callOnFlip(key_resp_starttask.clock.reset)  # t=0 on next screen flip
        event.clearEvents(eventType='keyboard')
    if key_resp_starttask.status == STARTED:
        theseKeys = event.getKeys(keyList=['5'])
        
        # check for quit:
        if "escape" in theseKeys:
            endExpNow = True
        if len(theseKeys) > 0:  # at least one key was pressed
            key_resp_starttask.keys = theseKeys[-1]  # just the last key pressed
            key_resp_starttask.rt = key_resp_starttask.clock.getTime()
            # a response ends the routine
            continueRoutine = False
    
    # check for quit (typically the Esc key)
    if endExpNow or event.getKeys(keyList=["escape"]):
        core.quit()
    
    # check if all components have finished
    if not continueRoutine:  # a component has requested a forced-end of Routine
        break
    continueRoutine = False  # will revert to True if at least one component still running
    for thisComponent in PleaseWaitComponents:
        if hasattr(thisComponent, "status") and thisComponent.status != FINISHED:
            continueRoutine = True
            break  # at least one component has not yet finished
    
    # refresh the screen
    if continueRoutine:  # don't flip if this routine is over or we'll get a blank screen
        win.flip()

# -------Ending Routine "PleaseWait"-------
for thisComponent in PleaseWaitComponents:
    if hasattr(thisComponent, "setAutoDraw"):
        thisComponent.setAutoDraw(False)
# check responses
if key_resp_starttask.keys in ['', [], None]:  # No response was made
    key_resp_starttask.keys=None
thisExp.addData('key_resp_starttask.keys',key_resp_starttask.keys)
if key_resp_starttask.keys != None:  # we had a response
    thisExp.addData('key_resp_starttask.rt', key_resp_starttask.rt)
thisExp.nextEntry()
# the Routine "PleaseWait" was not non-slip safe, so reset the non-slip timer
routineTimer.reset()

# ------Prepare to start Routine "BeginningFixation"-------
t = 0
BeginningFixationClock.reset()  # clock
frameN = -1
continueRoutine = True
routineTimer.add(15.000000)
# update component parameters for each repeat
gregsclock = core.Clock()
gcbeginningfixationstarttime = gregsclock.getTime()
# keep track of which components have finished
BeginningFixationComponents = [BeginningFixationCross]
for thisComponent in BeginningFixationComponents:
    if hasattr(thisComponent, 'status'):
        thisComponent.status = NOT_STARTED

# -------Start Routine "BeginningFixation"-------
while continueRoutine and routineTimer.getTime() > 0:
    # get current time
    t = BeginningFixationClock.getTime()
    frameN = frameN + 1  # number of completed frames (so 0 is the first frame)
    # update/draw components on each frame
    
    
    # *BeginningFixationCross* updates
    if t >= 0.0 and BeginningFixationCross.status == NOT_STARTED:
        # keep track of start time/frame for later
        BeginningFixationCross.tStart = t
        BeginningFixationCross.frameNStart = frameN  # exact frame index
        BeginningFixationCross.setAutoDraw(True)
    frameRemains = 0.0 + 15- win.monitorFramePeriod * 0.75  # most of one frame period left
    if BeginningFixationCross.status == STARTED and t >= frameRemains:
        BeginningFixationCross.setAutoDraw(False)
    
    # check for quit (typically the Esc key)
    if endExpNow or event.getKeys(keyList=["escape"]):
        core.quit()
    
    # check if all components have finished
    if not continueRoutine:  # a component has requested a forced-end of Routine
        break
    continueRoutine = False  # will revert to True if at least one component still running
    for thisComponent in BeginningFixationComponents:
        if hasattr(thisComponent, "status") and thisComponent.status != FINISHED:
            continueRoutine = True
            break  # at least one component has not yet finished
    
    # refresh the screen
    if continueRoutine:  # don't flip if this routine is over or we'll get a blank screen
        win.flip()

# -------Ending Routine "BeginningFixation"-------
for thisComponent in BeginningFixationComponents:
    if hasattr(thisComponent, "setAutoDraw"):
        thisComponent.setAutoDraw(False)
gcbeginningfixationendtime = gregsclock.getTime()
thisExp.addData('GCBeginningFixationStartTime',gcbeginningfixationstarttime)
thisExp.addData('GCBeginningFixationEndTime',gcbeginningfixationendtime)

# set up handler to look after randomisation of conditions etc
trials = data.TrialHandler(nReps=1, method='sequential', 
    extraInfo=expInfo, originPath=-1,
    trialList=data.importConditions('HaririTrials_Ver1.csv'),
    seed=None, name='trials')
thisExp.addLoop(trials)  # add the loop to the experiment
thisTrial = trials.trialList[0]  # so we can initialise stimuli with some values
# abbreviate parameter names if possible (e.g. rgb = thisTrial.rgb)
if thisTrial != None:
    for paramName in thisTrial:
        exec('{} = thisTrial[paramName]'.format(paramName))

for thisTrial in trials:
    currentLoop = trials
    # abbreviate parameter names if possible (e.g. rgb = thisTrial.rgb)
    if thisTrial != None:
        for paramName in thisTrial:
            exec('{} = thisTrial[paramName]'.format(paramName))
    
    # ------Prepare to start Routine "trial"-------
    t = 0
    trialClock.reset()  # clock
    frameN = -1
    continueRoutine = True
    # update component parameters for each repeat
    gcfacetrialstarttime = gregsclock.getTime()
    gregstrialclock = core.Clock()
    GCFaceTimeLoggerCheck = 0
    GCPostFaceFixationLoggerCheck = 0
    
    TopImage.setImage(Top)
    LeftFrame.setImage(EmptyFrame)
    LeftImage.setImage(Left)
    RightFrame.setImage(EmptyFrame)
    RightImage.setImage(Right)
    key_resp_trial = event.BuilderKeyResponse()
    
    
    # keep track of which components have finished
    trialComponents = [TopImage, LeftFrame, LeftImage, RightFrame, RightImage, key_resp_trial, TrialFixationEnd]
    for thisComponent in trialComponents:
        if hasattr(thisComponent, 'status'):
            thisComponent.status = NOT_STARTED
    
    # -------Start Routine "trial"-------
    while continueRoutine:
        # get current time
        t = trialClock.getTime()
        frameN = frameN + 1  # number of completed frames (so 0 is the first frame)
        # update/draw components on each frame
        
        if TopImage.status == STARTED and GCFaceTimeLoggerCheck == 0:
            gcfacestarttime = gregsclock.getTime()
            GCFaceTimeLoggerCheck = 1
        
        # *TopImage* updates
        if t >= 0.0 and TopImage.status == NOT_STARTED:
            # keep track of start time/frame for later
            TopImage.tStart = t
            TopImage.frameNStart = frameN  # exact frame index
            TopImage.setAutoDraw(True)
        frameRemains = 0.0 + TrialLength- win.monitorFramePeriod * 0.75  # most of one frame period left
        if TopImage.status == STARTED and t >= frameRemains:
            TopImage.setAutoDraw(False)
        
        # *LeftFrame* updates
        if t >= 0.0 and LeftFrame.status == NOT_STARTED:
            # keep track of start time/frame for later
            LeftFrame.tStart = t
            LeftFrame.frameNStart = frameN  # exact frame index
            LeftFrame.setAutoDraw(True)
        frameRemains = 0.0 + TrialLength- win.monitorFramePeriod * 0.75  # most of one frame period left
        if LeftFrame.status == STARTED and t >= frameRemains:
            LeftFrame.setAutoDraw(False)
        
        # *LeftImage* updates
        if t >= 0.0 and LeftImage.status == NOT_STARTED:
            # keep track of start time/frame for later
            LeftImage.tStart = t
            LeftImage.frameNStart = frameN  # exact frame index
            LeftImage.setAutoDraw(True)
        frameRemains = 0.0 + TrialLength- win.monitorFramePeriod * 0.75  # most of one frame period left
        if LeftImage.status == STARTED and t >= frameRemains:
            LeftImage.setAutoDraw(False)
        
        # *RightFrame* updates
        if t >= 0.0 and RightFrame.status == NOT_STARTED:
            # keep track of start time/frame for later
            RightFrame.tStart = t
            RightFrame.frameNStart = frameN  # exact frame index
            RightFrame.setAutoDraw(True)
        frameRemains = 0.0 + TrialLength- win.monitorFramePeriod * 0.75  # most of one frame period left
        if RightFrame.status == STARTED and t >= frameRemains:
            RightFrame.setAutoDraw(False)
        
        # *RightImage* updates
        if t >= 0.0 and RightImage.status == NOT_STARTED:
            # keep track of start time/frame for later
            RightImage.tStart = t
            RightImage.frameNStart = frameN  # exact frame index
            RightImage.setAutoDraw(True)
        frameRemains = 0.0 + TrialLength- win.monitorFramePeriod * 0.75  # most of one frame period left
        if RightImage.status == STARTED and t >= frameRemains:
            RightImage.setAutoDraw(False)
        
        # *key_resp_trial* updates
        if t >= 0.0 and key_resp_trial.status == NOT_STARTED:
            # keep track of start time/frame for later
            key_resp_trial.tStart = t
            key_resp_trial.frameNStart = frameN  # exact frame index
            key_resp_trial.status = STARTED
            # keyboard checking is just starting
            win.callOnFlip(key_resp_trial.clock.reset)  # t=0 on next screen flip
            event.clearEvents(eventType='keyboard')
        frameRemains = 0.0 + TrialLength- win.monitorFramePeriod * 0.75  # most of one frame period left
        if key_resp_trial.status == STARTED and t >= frameRemains:
            key_resp_trial.status = FINISHED
        if key_resp_trial.status == STARTED:
            theseKeys = event.getKeys(keyList=['1', '2'])
            
            # check for quit:
            if "escape" in theseKeys:
                endExpNow = True
            if len(theseKeys) > 0:  # at least one key was pressed
                if key_resp_trial.keys == []:  # then this was the first keypress
                    key_resp_trial.keys = theseKeys[0]  # just the first key pressed
                    key_resp_trial.rt = key_resp_trial.clock.getTime()
                    # was this 'correct'?
                    if (key_resp_trial.keys == str(Correct)) or (key_resp_trial.keys == Correct):
                        key_resp_trial.corr = 1
                    else:
                        key_resp_trial.corr = 0
        if key_resp_trial.keys == '1':
            LeftFrame.setImage(os.path.join(_thisDir,SelectedFrame))
            LeftImage.setImage(os.path.join(_thisDir,Left))
        if key_resp_trial.keys == '2':
            RightFrame.setImage(os.path.join(_thisDir,SelectedFrame))
            RightImage.setImage(os.path.join(_thisDir,Right))
        if TrialFixationEnd.status == STARTED and GCPostFaceFixationLoggerCheck == 0:
            gcpostfacefixationstarttime = gregsclock.getTime()
            GCPostFaceFixationLoggerCheck = 1
        
        # *TrialFixationEnd* updates
        if t >= TrialLength and TrialFixationEnd.status == NOT_STARTED:
            # keep track of start time/frame for later
            TrialFixationEnd.tStart = t
            TrialFixationEnd.frameNStart = frameN  # exact frame index
            TrialFixationEnd.setAutoDraw(True)
        frameRemains = TrialLength + FixationLength- win.monitorFramePeriod * 0.75  # most of one frame period left
        if TrialFixationEnd.status == STARTED and t >= frameRemains:
            TrialFixationEnd.setAutoDraw(False)
        
        
        # check for quit (typically the Esc key)
        if endExpNow or event.getKeys(keyList=["escape"]):
            core.quit()
        
        # check if all components have finished
        if not continueRoutine:  # a component has requested a forced-end of Routine
            break
        continueRoutine = False  # will revert to True if at least one component still running
        for thisComponent in trialComponents:
            if hasattr(thisComponent, "status") and thisComponent.status != FINISHED:
                continueRoutine = True
                break  # at least one component has not yet finished
        
        # refresh the screen
        if continueRoutine:  # don't flip if this routine is over or we'll get a blank screen
            win.flip()
    
    # -------Ending Routine "trial"-------
    for thisComponent in trialComponents:
        if hasattr(thisComponent, "setAutoDraw"):
            thisComponent.setAutoDraw(False)
    
    
    # check responses
    if key_resp_trial.keys in ['', [], None]:  # No response was made
        key_resp_trial.keys=None
        # was no response the correct answer?!
        if str(Correct).lower() == 'none':
           key_resp_trial.corr = 1;  # correct non-response
        else:
           key_resp_trial.corr = 0;  # failed to respond (incorrectly)
    # store data for trials (TrialHandler)
    trials.addData('key_resp_trial.keys',key_resp_trial.keys)
    trials.addData('key_resp_trial.corr', key_resp_trial.corr)
    if key_resp_trial.keys != None:  # we had a response
        trials.addData('key_resp_trial.rt', key_resp_trial.rt)
    
    gcpostfacefixationendtime = gregsclock.getTime()
    trials.addData('GCFaceStartTime',gcfacestarttime)
    trials.addData('GCPostFaceFixationStartTime',gcpostfacefixationstarttime)
    trials.addData('GCPostFaceFixationEndTime',gcpostfacefixationendtime)
    if key_resp_trial.keys != None:  # we had a response
        trials.addData('key_resp_trial.rt', key_resp_trial.rt)
    # the Routine "trial" was not non-slip safe, so reset the non-slip timer
    routineTimer.reset()
    thisExp.nextEntry()
    
# completed 1 repeats of 'trials'

# get names of stimulus parameters
if trials.trialList in ([], [None], None):
    params = []
else:
    params = trials.trialList[0].keys()
# save data for this loop
trials.saveAsText(filename + 'trials.csv', delim=',',
    stimOut=params,
    dataOut=['n','all_mean','all_std', 'all_raw'])

# ------Prepare to start Routine "EndingFixation"-------
t = 0
EndingFixationClock.reset()  # clock
frameN = -1
continueRoutine = True
routineTimer.add(15.000000)
# update component parameters for each repeat
gcendingfixationstarttime = gregsclock.getTime()

# keep track of which components have finished
EndingFixationComponents = [EndingFixationCross]
for thisComponent in EndingFixationComponents:
    if hasattr(thisComponent, 'status'):
        thisComponent.status = NOT_STARTED

# -------Start Routine "EndingFixation"-------
while continueRoutine and routineTimer.getTime() > 0:
    # get current time
    t = EndingFixationClock.getTime()
    frameN = frameN + 1  # number of completed frames (so 0 is the first frame)
    # update/draw components on each frame
    
    
    # *EndingFixationCross* updates
    if t >= 0.0 and EndingFixationCross.status == NOT_STARTED:
        # keep track of start time/frame for later
        EndingFixationCross.tStart = t
        EndingFixationCross.frameNStart = frameN  # exact frame index
        EndingFixationCross.setAutoDraw(True)
    frameRemains = 0.0 + 15- win.monitorFramePeriod * 0.75  # most of one frame period left
    if EndingFixationCross.status == STARTED and t >= frameRemains:
        EndingFixationCross.setAutoDraw(False)
    
    
    # check for quit (typically the Esc key)
    if endExpNow or event.getKeys(keyList=["escape"]):
        core.quit()
    
    # check if all components have finished
    if not continueRoutine:  # a component has requested a forced-end of Routine
        break
    continueRoutine = False  # will revert to True if at least one component still running
    for thisComponent in EndingFixationComponents:
        if hasattr(thisComponent, "status") and thisComponent.status != FINISHED:
            continueRoutine = True
            break  # at least one component has not yet finished
    
    # refresh the screen
    if continueRoutine:  # don't flip if this routine is over or we'll get a blank screen
        win.flip()

# -------Ending Routine "EndingFixation"-------
for thisComponent in EndingFixationComponents:
    if hasattr(thisComponent, "setAutoDraw"):
        thisComponent.setAutoDraw(False)

gcendingfixationendtime = gregsclock.getTime()
thisExp.addData('GCEndingFixationStartTime',gcendingfixationstarttime)
thisExp.addData('GCEndingFixationEndTime',gcendingfixationendtime)







# these shouldn't be strictly necessary (should auto-save)
thisExp.saveAsWideText(filename+'.csv')
thisExp.saveAsPickle(filename)
logging.flush()
# make sure everything is closed down
thisExp.abort()  # or data files will save again on exit
win.close()
core.quit()

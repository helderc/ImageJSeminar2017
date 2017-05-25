clear all; close all; clc;

displayReasults = 0;

fprintf('\n[*] Launching Fiji...\n');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Starting Miji, the 'connector' between MATLAB and ImageJ/Fiji
Miji(false);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Importing Java classes:

import java.lang.Integer
import java.util.HashMap
import ij.*
import fiji.plugin.trackmate.* 
import fiji.plugin.trackmate.detection.*
import fiji.plugin.trackmate.features.*
import fiji.plugin.trackmate.features.track.*
import fiji.plugin.trackmate.tracking.*
import fiji.plugin.trackmate.visualization.hyperstack.*
import fiji.plugin.trackmate.util.*
    

fullpath = 'C:\Users\Helder\Documents\MATLAB\TorVergata\FunctionsProcess\Seminar\';
% ordinary filename:
fn = strcat(fullpath, 'DBT_L_MLO_Seminar.tiff');


imp = ij.ImagePlus(fn);
%imp.show()


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Necessary correction for TrackMate: 
%   swap Z (slices) by T (frames)
% ImagePlus DOC: Returns the dimensions of this image 
% (width, height, nChannels, nSlices, nFrames) as a 5 element int array.
dims = imp.getDimensions();
% public void setDimensions(int nChannels, int nSlices, int nFrames)
imp.setDimensions(dims(3), dims(5), dims(4));



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Create the model object now

% Some of the parameters we configure below need to have
% a reference to the model at creation. So we create an
% empty model now.
model = fiji.plugin.trackmate.Model();

% Send all messages to ImageJ log window.
% model.setLogger(fiji.plugin.trackmate.Logger.IJ_LOGGER)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Prepare settings object

settings = fiji.plugin.trackmate.Settings();
settings.setFrom(imp)

% Configure detector - We use a java map
settings.detectorFactory = fiji.plugin.trackmate.detection.LogDetectorFactory();
   
settings.detectorSettings.put('DO_SUBPIXEL_LOCALIZATION', true);
settings.detectorSettings.put('DO_MEDIAN_FILTERING', false);
settings.detectorSettings.put('THRESHOLD', 10.0);
settings.detectorSettings.put('RADIUS', 5.0);
settings.detectorSettings.put('TARGET_CHANNEL', 1);


% Configure spot filters - Classical filter on quality
filter1 = fiji.plugin.trackmate.features.FeatureFilter('QUALITY', 15.841734170913696, true);
settings.addSpotFilter(filter1)
    


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Configure tracker - We want to allow splits and fusions
settings.trackerFactory  = 	sparselap.SimpleSparseLAPTrackerFactory();
% get default parameters
settings.trackerSettings = fiji.plugin.trackmate.tracking.LAPUtils.getDefaultLAPSettingsMap();

settings.trackerSettings.put('LINKING_MAX_DISTANCE', 20.0);
settings.trackerSettings.put('ALLOW_GAP_CLOSING', true);
settings.trackerSettings.put('GAP_CLOSING_MAX_DISTANCE', 10.0);
settings.trackerSettings.put('MAX_FRAME_GAP', Integer.valueOf(10));
settings.trackerSettings.put('ALLOW_TRACK_SPLITTING', false);
settings.trackerSettings.put('SPLITTING_MAX_DISTANCE', 15.0);
settings.trackerSettings.put('ALLOW_TRACK_MERGING', false);
settings.trackerSettings.put('MERGING_MAX_DISTANCE', 15.0);


% Configure track analyzers - Later on we want to filter out tracks 
% based on their displacement, so we need to state that we want 
% track displacement to be calculated. By default, out of the GUI, 
% not features are calculated. 

% The displacement feature is provided by the TrackDurationAnalyzer.
settings.addTrackAnalyzer(fiji.plugin.trackmate.features.track.TrackBranchingAnalyzer());


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Instantiate the TrackMate only to get the optimla values of the features.
trackmate = fiji.plugin.trackmate.TrackMate(model, settings);
trackmate.setNumThreads(1); 

% Part of trackmate.process(), that will be done later mus to be done now
% to get the optimal values.
trackmate.execDetection();
trackmate.execInitialSpotFiltering();
trackmate.computeSpotFeatures( false );
trackmate.execSpotFiltering(false);
trackmate.execTracking();
trackmate.computeTrackFeatures(false);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Process necessary to get optimal values of the features
trackFeatureValues = model.getFeatureModel.getTrackFeatureValues();

featureValues = trackFeatureValues.get('NUMBER_SPOTS');
optimalNumberSpots = fiji.plugin.trackmate.util.TMUtils.otsuThreshold(featureValues);

featureValues = trackFeatureValues.get('NUMBER_GAPS');
optimalNumberGaps = fiji.plugin.trackmate.util.TMUtils.otsuThreshold(featureValues);


fprintf('\n[*] Track filter - Optimal Number of Spots: %.6f', optimalNumberSpots);
fprintf('\n[*] Track filter - Optimal Number of Gaps: %.6f\n\n', optimalNumberGaps);

% Configure track filters
filter2 = fiji.plugin.trackmate.features.FeatureFilter('NUMBER_SPOTS', optimalNumberSpots, true);
settings.addTrackFilter(filter2);

filter3 = fiji.plugin.trackmate.features.FeatureFilter('NUMBER_GAPS', optimalNumberGaps, false);
settings.addTrackFilter(filter3);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Process...

ok = trackmate.checkInput();
if ~ok
    display(trackmate.getErrorMessage())
end

ok = trackmate.process();
if ~ok
    display(trackmate.getErrorMessage())
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Display results

if (displayReasults)
    selectionModel = fiji.plugin.trackmate.SelectionModel(model);
    displayer = fiji.plugin.trackmate.visualization.hyperstack.HyperStackDisplayer(model, selectionModel, imp);
    displayer.render()
    displayer.refresh()
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Saving file with 'tracks' and 'configs'
% creating the file name to save the tracks
xml_fn = 'Seminar_Tracks.xml';

file = java.io.File(xml_fn);
fiji.plugin.trackmate.action.ExportTracksToXML.export(model, settings, file);



fprintf('\n[*] XML file saved: %s', xml_fn);

fprintf('\n[*] Finished! (TrackMateFiji.m)\n\n');

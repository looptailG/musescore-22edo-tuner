/*
	22EDO Tuner plugin for Musescore.
	Copyright (C) 2024 Alessandro Culatti

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

import QtQuick 2.2
import FileIO 3.0
import MuseScore 3.0
import "libs/AccidentalUtils.js" as AccidentalUtils
import "libs/DateUtils.js" as DateUtils
import "libs/IterationUtils.js" as IterationUtils
import "libs/NoteUtils.js" as NoteUtils
import "libs/StringUtils.js" as StringUtils
import "libs/TuningUtils.js" as TuningUtils

MuseScore
{
	title: "22EDO Tuner";
	description: "Retune the selection, or the whole score if nothing is selected, to 22EDO.";
	categoryCode: "playback";
	thumbnailName: "22EdoThumbnail.png";
	version: "2.1.0";
	
	property variant settings: {};

	// Size in cents of an EDO step.
	property var stepSize: 1200.0 / 22;
	// Difference in cents between a 12EDO and a 31EDO fifth.
	property var fifthDeviation: 700 - 13 * stepSize;
	// Reference note, which has a tuning offset of zero.
	property var referenceNote: "";
	
	// Map containing the amount of EDO steps of every supported accidental.
	property variant supportedAccidentals:
	{
		"NONE": 0,
		"FLAT": -3,
		"NATURAL": 0,
		"SHARP": 3,
		"SHARP2": 6,
		"FLAT2": -6,
		"NATURAL_FLAT": -3,
		"NATURAL_SHARP": 3,
		"FLAT_ARROW_UP": -2,
		"FLAT_ARROW_DOWN": -4,
		"NATURAL_ARROW_UP": 1,
		"NATURAL_ARROW_DOWN": -1,
		"SHARP_ARROW_UP": 4,
		"SHARP_ARROW_DOWN": 2,
		"SHARP2_ARROW_UP": 7,
		"SHARP2_ARROW_DOWN": 5,
		"FLAT2_ARROW_UP": -5,
		"FLAT2_ARROW_DOWN": -7,
		"DOUBLE_FLAT_ONE_ARROW_DOWN": -7,
		"FLAT_ONE_ARROW_DOWN": -4,
		"NATURAL_ONE_ARROW_DOWN": -1,
		"SHARP_ONE_ARROW_DOWN": 2,
		"DOUBLE_SHARP_ONE_ARROW_DOWN": 5,
		"DOUBLE_FLAT_ONE_ARROW_UP": -5,
		"FLAT_ONE_ARROW_UP": -2,
		"NATURAL_ONE_ARROW_UP": 1,
		"SHARP_ONE_ARROW_UP": 4,
		"DOUBLE_SHARP_ONE_ARROW_UP": 7,
		"DOUBLE_FLAT_TWO_ARROWS_DOWN": -8,
		"FLAT_TWO_ARROWS_DOWN": -5,
		"NATURAL_TWO_ARROWS_DOWN": -2,
		"SHARP_TWO_ARROWS_DOWN": 1,
		"DOUBLE_SHARP_TWO_ARROWS_DOWN": 4,
		"DOUBLE_FLAT_TWO_ARROWS_UP": -4,
		"FLAT_TWO_ARROWS_UP": -1,
		"NATURAL_TWO_ARROWS_UP": 2,
		"SHARP_TWO_ARROWS_UP": 5,
		"DOUBLE_SHARP_TWO_ARROWS_UP": 8,
	}
	
	// Map containing the previous microtonal accidentals in the current
	// measure.  The keys are formatted as note letter concatenated with the
	// note octave, for example C4.  The value is the last microtonal accidental
	// that was applied to that note within the current measure.
	property variant previousAccidentals: {}
	
	// Map containing the alteration presents in the current custom key
	// signature, if any.  The keys are the names of the notes, and the values
	// are the accidentals applied to them.  It supports only octave-repeating
	// key signatures.
	property variant currentCustomKeySignature: {}
	// Regex used for checking if a string is valid as a custom key signature.
	property var customKeySignatureRegex: /^(vbb|bb|\^bb|vb|b|\^b|vh|h|\^h|v#|#|\^#|vx|x|\^x|)(?:\.(?:vbb|bb|\^bb|vb|b|\^b|vh|h|\^h|v#|#|\^#|vx|x|\^x|)){6}$/;
	// Array containing the notes in the order they appear in the custom key
	// signature string.
	property var customKeySignatureNoteOrder: ["F", "C", "G", "D", "A", "E", "B"];
	
	// Amount of notes which were tuned successfully.
	property var tunedNotes: 0;
	// Total amount of notes encountered in the portion of the score to tune.
	property var totalNotes: 0;
	
	FileIO
	{
		id: logger;
		source: Qt.resolvedUrl(".").toString().substring(8) + "logs/" + DateUtils.getFileDateTime() + "_log.txt";
		property var logMessages: "";
		property var currentLogLevel: 2;
		property variant logLevels:
		{
			0: " | TRACE   | ",
			1: " | INFO    | ",
			2: " | WARNING | ",
			3: " | ERROR   | ",
			4: " | FATAL   | ",
		}
		
		function log(message, logLevel)
		{
			if (logLevel === undefined)
			{
				logLevel = 1;
			}
			
			if (logLevel >= currentLogLevel)
			{
				logMessages += DateUtils.getRFC3339DateTime() + logLevels[logLevel] + message + "\n";
				write(logMessages);
			}
		}
		
		function trace(message)
		{
			log(message, 0);
		}
		
		function warning(message)
		{
			log(message, 2);
		}
		
		function error(message)
		{
			log(message, 3);
		}
		
		function fatal(message)
		{
			log(message, 4);
		}
	}

	FileIO
	{
		id: settingsReader;
		source: Qt.resolvedUrl(".").toString().substring(8) + "Settings.tsv";
		
		onError:
		{
			logger.error(msg);
		}
	}

	onRun:
	{
		try
		{
			// Read settings file.
			settings = {};
			var settingsFileContent = settingsReader.read().split("\n");
			for (var i = 0; i < settingsFileContent.length; i++)
			{
				if (settingsFileContent[i].trim() != "")
				{
					var rowData = StringUtils.parseTsvRow(settingsFileContent[i]);
					settings[rowData[0]] = rowData[1];
				}
			}
			logger.currentLogLevel = parseInt(settings["LogLevel"]);
			referenceNote = settings["ReferenceNote"];
			
			logger.log("-- 22EDO Tuner -- Version " + version + " --");
			logger.log("Log level set to: " + logger.currentLogLevel);
			logger.log("Reference note set to: " + referenceNote);
			
			IterationUtils.iterate(
				curScore,
				{
					"onStaffStart": onStaffStart,
					"onNewMeasure": onNewMeasure,
					"onKeySignatureChange": onKeySignatureChange,
					"onAnnotation": onAnnotation,
					"onNote": onNote
				},
				logger
			);
			
			logger.log("Notes tuned: " + tunedNotes + " / " + totalNotes);
		}
		catch (error)
		{
			logger.fatal(error);
		}
		finally
		{
			quit();
		}
	}

	function onStaffStart()
	{
		currentCustomKeySignature = {};
		previousAccidentals = {};
	}
	
	function onNewMeasure()
	{
		previousAccidentals = {};
	}
	
	function onKeySignatureChange(keySignature)
	{
		logger.log("Key signature change, emptying the custom key signature map.");
		currentCustomKeySignature = {};
	}
	
	function onAnnotation(annotation)
	{
		let annotationText = annotation.text.replace(/\s*/g, "");
		if (customKeySignatureRegex.test(annotationText))
		{
			logger.log("Applying custom key signature: " + annotationText);
			currentCustomKeySignature = {};
			try
			{
				let annotationTextSplitted = annotationText.split(".");
				for (let i = 0; i < annotationTextSplitted.length; i++)
				{
					let currentNote = customKeySignatureNoteOrder[i];
					let currentAccidental = annotationTextSplitted[i];
					let accidentalName = "";
					switch (currentAccidental)
					{
						// Non-microtonal accidentals are automatically handled
						// by Musescore even in custom key signatures, so we
						// only have to check for microtonal accidentals.
						case "bb":
						case "b":
						case "":
						case "h":
						case "#":
						case "x":
							break;

						case "vbb":
							accidentalName = "FLAT2_ARROW_DOWN";
							break;

						case "^bb":
							accidentalName = "FLAT2_ARROW_UP";
							break;

						case "vb":
							accidentalName = "FLAT_ARROW_DOWN";
							break;

						case "^b":
							accidentalName = "FLAT_ARROW_UP";
							break;

						case "vh":
							accidentalName = "NATURAL_ARROW_DOWN";
							break;

						case "^h":
							accidentalName = "NATURAL_ARROW_UP";
							break;

						case "v#":
							accidentalName = "SHARP_ARROW_DOWN";
							break;

						case "^#":
							accidentalName = "SHARP_ARROW_UP";
							break;

						case "vx":
							accidentalName = "SHARP2_ARROW_DOWN";
							break;

						case "^x":
							accidentalName = "SHARP2_ARROW_UP";
							break;

						default:
							throw "Unsupported accidental in the custom key signature: " + currentAccidental;
					}
					if (accidentalName != "")
					{
						currentCustomKeySignature[currentNote] = accidentalName;
					}
				}
			}
			catch (error)
			{
				logger.error(error);
				currentCustomKeySignature = {};
			}
		}
	}
	
	function onNote(note)
	{
		totalNotes++;
		
		try
		{
			note.tuning = TuningUtils.edoTuningOffset(
				note, NoteUtils.getNoteLetter(note, "tpc"), AccidentalUtils.getAccidentalName(note), NoteUtils.getOctave(note), referenceNote,
				stepSize, fifthDeviation, supportedAccidentals, AccidentalUtils.ACCIDENTAL_DATA,
				previousAccidentals, currentCustomKeySignature,
				logger
			);
			tunedNotes++;
		}
		catch (error)
		{
			logger.error(error);
		}
	}
}

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
import "libs/NoteUtils.js" as NoteUtils
import "libs/StringUtils.js" as StringUtils
import "libs/TuningUtils.js" as TuningUtils

MuseScore
{
	title: "22EDO Tuner";
	description: "Retune the selection, or the whole score if nothing is selected, to 22EDO.";
	categoryCode: "playback";
	thumbnailName: "22EdoThumbnail.png";
	version: "2.0.0-alpha";
	
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
		
		function writeLogMessages()
		{
			if (logMessages != "")
			{
				write(logMessages);
			}
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
			
			curScore.startCmd();
			
			// Calculate the portion of the score to tune.
			var cursor = curScore.newCursor();
			var startStaff;
			var endStaff;
			var startTick;
			var endTick;
			cursor.rewind(Cursor.SELECTION_START);
			if (!cursor.segment)
			{
				logger.log("Tuning the entire score.");
				startStaff = 0;
				endStaff = curScore.nstaves - 1;
				startTick = 0;
				endTick = curScore.lastSegment.tick + 1;
			}
			else
			{
				logger.log("Tuning only the current selection.");
				startStaff = cursor.staffIdx;
				startTick = cursor.tick;
				cursor.rewind(Cursor.SELECTION_END);
				endStaff = cursor.staffIdx;
				if (cursor.tick == 0)
				{
					// If the selection includes the last measure of the score,
					// .rewind() overflows and goes back to tick 0.
					endTick = curScore.lastSegment.tick + 1;
				}
				else
				{
					endTick = cursor.tick;
				}
				logger.trace("Tuning only ticks: " + startTick + " - " + endTick);
				logger.trace("Tuning only staffs: " + startStaff + " - " + endStaff);
			}
			
			tunedNotes = 0;
			totalNotes = 0;
			// Loop on the portion of the score to tune.
			for (var staff = startStaff; staff <= endStaff; staff++)
			{
				for (var voice = 0; voice < 4; voice++)
				{
					logger.log("Tuning Staff: " + staff + "; Voice: " + voice);
					
					cursor.voice = voice;
					cursor.staffIdx = staff;
					cursor.rewindToTick(startTick);
					
					currentCustomKeySignature = {};
					previousAccidentals = {};

					// Loop on elements of a voice.
					while (cursor.segment && (cursor.tick < endTick))
					{
						if (cursor.segment.tick == cursor.measure.firstSegment.tick)
						{
							// New measure, empty the previous accidentals map.
							previousAccidentals = {};
						}
						
						// Check for key signature change.
						// TODO: This implementation is very ineffcient, as this piece of code is called on every element when the key signature is not empty.  Find a way to call this only when the key signature actually change.
						if (cursor.keySignature)
						{
							// The key signature has changed, empty the custom
							// key signature map.
							// TODO: This if is necessary only because the previous if is not true only when there is an actual key signature change.  This way we check if the mapping was not empty before, and thus actually needs to be emptied now.
							if (Object.keys(currentCustomKeySignature).length != 0)
							{
								logger.log("Key signature change, emptying the custom key signature map.");
								currentCustomKeySignature = {};
							}
						}
						// Check if there is a text indicating a custom key
						// signature change.
						for (var i = 0; i < cursor.segment.annotations.length; i++)
						{
							var annotationText = cursor.segment.annotations[i].text;
							if (annotationText)
							{
								annotationText = annotationText.replace(/\s*/g, "");
								if (customKeySignatureRegex.test(annotationText))
								{
									logger.log("Applying the current custom key signature: " + annotationText);
									currentCustomKeySignature = {};
									try
									{
										var annotationTextSplitted = annotationText.split(".");
										for (var j = 0; j < annotationTextSplitted.length; j++)
										{
											var currentNote = customKeySignatureNoteOrder[j];
											var currentAccidental = annotationTextSplitted[j].trim();
											var accidentalName = "";
											switch (currentAccidental)
											{
												// Non-microtonal accidentals
												// are automatically handled by
												// Musescore even in custom key
												// signatures, so we only have
												// to check for microtonal
												// accidentals.
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
						}
						
						// Tune notes.
						if (cursor.element)
						{
							if (cursor.element.type == Element.CHORD)
							{
								// Iterate through every grace chord.
								var graceChords = cursor.element.graceNotes;
								for (var i = 0; i < graceChords.length; i++)
								{
									var notes = graceChords[i].notes;
									for (var j = 0; j < notes.length; j++)
									{
										try
										{
											notes[j].tuning = calculateTuningOffset(notes[j]);
										}
										catch (error)
										{
											logger.error(error);
										}
									}
								}

								// Iterate through every chord note.
								var notes = cursor.element.notes;
								for (var i = 0; i < notes.length; i++)
								{
									try
									{
										notes[i].tuning = calculateTuningOffset(notes[i]);
									}
									catch (error)
									{
										logger.error(error);
									}
								}
							}
						}

						cursor.next();
					}
				}
			}
			
			logger.log("Notes tuned: " + tunedNotes + " / " + totalNotes);
			
			curScore.endCmd();
		}
		catch (error)
		{
			logger.fatal(error);
		}
		finally
		{
			logger.writeLogMessages();
			
			quit();
		}
	}

	/**
	 * Returns the amount of cents necessary to tune the input note to 22EDO.
	 */
	function calculateTuningOffset(note)
	{
		totalNotes += 1;
	
		var noteLetter = NoteUtils.getNoteLetter(note, "tpc");
		var accidentalName = AccidentalUtils.getAccidentalName(note);
		var noteOctave = NoteUtils.getOctave(note);
		var noteNameOctave = noteLetter + noteOctave;
		var completeNoteName = noteLetter + " " + accidentalName + " " + noteOctave;
		logger.trace("Tuning note: " + completeNoteName);
		
		try
		{
			var tuningOffset = -TuningUtils.circleOfFifthsDistance(note, referenceNote) * fifthDeviation;
			logger.trace("Base tuning offset: " + tuningOffset);
			
			// Certain accidentals, like the microtonal accidentals, are not
			// conveyed by the tpc property, but are instead handled directly
			// via a tuning offset.
			// Check which accidental is applied to the note.
			if (accidentalName == "NONE")
			{
				// If the note does not have any accidental applied to it, check
				// if the same note previously in the measure was modified by a
				// microtonal accidental.
				if (previousAccidentals.hasOwnProperty(noteNameOctave))
				{
					accidentalName = previousAccidentals[noteNameOctave];
					logger.trace("Applying to the following accidental to the current note from a previous note within the measure: " + accidentalName);
				}
				// If the note still does not have an accidental applied to it,
				// check if it's modified by a custom key signature.
				if (accidentalName == "NONE")
				{
					if (currentCustomKeySignature.hasOwnProperty(noteLetter))
					{
						accidentalName = currentCustomKeySignature[noteLetter];
						logger.trace("Applying the following accidental from a custom key signature: " + accidentalName);
					}
				}
			}
			else
			{
				// Save the accidental in the previous accidentals map for this
				// note.
				previousAccidentals[noteNameOctave] = accidentalName;
			}
			// Check if the accidental is handled by a tuning offset.
			if (!AccidentalUtils.ACCIDENTAL_DATA[accidentalName]["TPC"])
			{
				// Undo the default tuning offset which is applied to certain
				// accidentals.
				// The default tuning offset is applied only if an actual
				// microtonal accidental is applied to the current note.  For
				// this reason, we must check getAccidentalName() on the current
				// note, it is not sufficient to check the value saved in
				// accidentalName.
				var actualAccidentalName = AccidentalUtils.getAccidentalName(note);
				var actualAccidentalOffset = AccidentalUtils.ACCIDENTAL_DATA[actualAccidentalName]["DEFAULT_OFFSET"];
				tuningOffset -= actualAccidentalOffset;
				logger.trace("Undoing the default tuning offset of: " + actualAccidentalOffset);
				
				// Apply the tuning offset for this specific accidental.
				var edoSteps = supportedAccidentals[accidentalName];
				if (edoSteps === undefined)
				{
					throw "Unsupported accidental: " + accidentalName;
				}
				tuningOffset += edoSteps * stepSize;
				logger.trace("Offsetting the tuning by " + edoSteps + " EDO steps.");
			}
			
			tunedNotes += 1;
			logger.trace("Final tuning offset: " + tuningOffset);
			return tuningOffset;
		}
		catch (error)
		{
			logger.error("Encontered the following exception while tuning " + completeNoteName + ": " + error);
			// Leave the tuning of the input note unchanged.
			return note.tuning;
		}
	}
}

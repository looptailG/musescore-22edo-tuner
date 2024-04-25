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
import QtQuick.Dialogs 1.1
import MuseScore 3.0

MuseScore
{
	menuPath: "Plugins.Tuner.22EDO"
	description: "Retune the selection, or the whole score if nothing is selected, to 22EDO."
	version: "0.1.0"
	
	Component.onCompleted:
	{
		if (mscoreMajorVersion >= 4)
		{
			title = qsTr("22EDO Tuner");
			thumbnailName = "22EdoThumbnail.png";
			categoryCode = "playback";
		}
	}

	// Size in cents of an EDO step.
	property var stepSize: 1200.0 / 22;
	
	// Map containing the properties of every supported accidental.  The
	// accidentals with a "DEFAULT_OFFSET" property are those not handled by the
	// tpc property, but instead by a tuning offset.
	// Values taken from: Musescore/src/engraving/dom/accidental.cpp
	property variant supportedAccidentals:
	{
		"NONE":
		{
			"EDO_STEPS": 0,
		},
		"FLAT":
		{
			"EDO_STEPS": -3,
		},
		"NATURAL":
		{
			"EDO_STEPS": 0,
		},
		"SHARP":
		{
			"EDO_STEPS": 3,
		},
		"SHARP2":
		{
			"EDO_STEPS": 6,
		},
		"FLAT2":
		{
			"EDO_STEPS": -6,
		},
		"FLAT_ARROW_UP":
		{
			"EDO_STEPS": -2,
			"DEFAULT_OFFSET": -50,
		},
		"FLAT_ARROW_DOWN":
		{
			"EDO_STEPS": -4,
			"DEFAULT_OFFSET": -150,
		},
		"NATURAL_ARROW_UP":
		{
			"EDO_STEPS": 1,
			"DEFAULT_OFFSET": 50,
		},
		"NATURAL_ARROW_DOWN":
		{
			"EDO_STEPS": -1,
			"DEFAULT_OFFSET": -50,
		},
		"SHARP_ARROW_UP":
		{
			"EDO_STEPS": 4,
			"DEFAULT_OFFSET": 150,
		},
		"SHARP_ARROW_DOWN":
		{
			"EDO_STEPS": 2,
			"DEFAULT_OFFSET": 50,
		},
		"SHARP2_ARROW_UP":
		{
			"EDO_STEPS": 7,
			"DEFAULT_OFFSET": 250,
		},
		"SHARP2_ARROW_DOWN":
		{
			"EDO_STEPS": 5,
			"DEFAULT_OFFSET": 150,
		},
		"FLAT2_ARROW_UP":
		{
			"EDO_STEPS": -5,
			"DEFAULT_OFFSET": -150,
		},
		"FLAT2_ARROW_DOWN":
		{
			"EDO_STEPS": -7,
			"DEFAULT_OFFSET": -250,
		},
		"DOUBLE_FLAT_ONE_ARROW_DOWN":
		{
			"EDO_STEPS": -7,
			"DEFAULT_OFFSET": 0,
		},
		"FLAT_ONE_ARROW_DOWN":
		{
			"EDO_STEPS": -4,
			"DEFAULT_OFFSET": 0,
		},
		"NATURAL_ONE_ARROW_DOWN":
		{
			"EDO_STEPS": -1,
			"DEFAULT_OFFSET": 0,
		},
		"SHARP_ONE_ARROW_DOWN":
		{
			"EDO_STEPS": 2,
			"DEFAULT_OFFSET": 0,
		},
		"DOUBLE_SHARP_ONE_ARROW_DOWN":
		{
			"EDO_STEPS": 5,
			"DEFAULT_OFFSET": 0,
		},
		"DOUBLE_FLAT_ONE_ARROW_UP":
		{
			"EDO_STEPS": -5,
			"DEFAULT_OFFSET": 0,
		},
		"FLAT_ONE_ARROW_UP":
		{
			"EDO_STEPS": -2,
			"DEFAULT_OFFSET": 0,
		},
		"NATURAL_ONE_ARROW_UP":
		{
			"EDO_STEPS": 1,
			"DEFAULT_OFFSET": 0,
		},
		"SHARP_ONE_ARROW_UP":
		{
			"EDO_STEPS": 4,
			"DEFAULT_OFFSET": 0,
		},
		"DOUBLE_SHARP_ONE_ARROW_UP":
		{
			"EDO_STEPS": 7,
			"DEFAULT_OFFSET": 0,
		},
	}
	
	property var showLog: false;
	property var maxLines: 50;
	MessageDialog
	{
		id: debugLogger;
		title: "22EDO Tuner - Debug";
		text: "";

		function log(message, isErrorMessage)
		{
			if (showLog || isErrorMessage)
			{
				text += message + "\n";
			}
		}
		
		function showLogMessages()
		{
			if (text != "")
			{
				// Truncate the message to a maximum number of lines, to prevent
				// issues with the message box being too large.
				var messageLines = text.split("\n").slice(0, maxLines);
				text = messageLines.join("\n") + "\n" + "...";
				debugLogger.open();
			}
		}
	}

	onRun:
	{
		logMessage("-- 22EDO Tuner -- Version " + version +  " --");
	
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
			// Tuning the entire score.
			startStaff = 0;
			endStaff = curScore.nstaves - 1;
			startTick = 0;
			endTick = curScore.lastSegment.tick + 1;
			logMessage("Tuning the entire score.");
		}
		else
		{
			// Tuning only the selection.
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
			logMessage("Tuning only the portion of the score between staffs " + startStaff + " - " + endStaff + ", and between ticks " + startTick + " - " + endTick + ".");
		}

		// Loop on the portion of the score to tune.
		for (var staff = startStaff; staff <= endStaff; staff++)
		{
			for (var voice = 0; voice < 4; voice++)
			{
				logMessage("-- Tuning Staff: " + staff + " -- Voice: " + voice + " --");
				
				cursor.voice = voice;
				cursor.staffIdx = staff;
				cursor.rewindToTick(startTick);

				// Loop on elements of a voice.
				while (cursor.segment && (cursor.tick < endTick))
				{
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
										logMessage(error, true);
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
									logMessage(error, true);
								}
							}
						}
					}

					cursor.next();
				}
			}
		}
		
		curScore.endCmd();
		
		debugLogger.showLogMessages();

		if (mscoreMajorVersion >= 4)
		{
			quit();
		}
		else
		{
			Qt.quit();
		}
	}

	/**
	 * Returns the amount of cents necessary to tune the input note to 22EDO.
	 */
	function calculateTuningOffset(note)
	{
		logMessage("Tuning note: " + calculateNoteName(note));
		
		var tuningOffset = 0;
		
		

		return tuningOffset;
	}
	
	/**
	 * Return the english note name for the input note, written with ASCII
	 * characters only.
	 */
	function calculateNoteName(note)
	{
		var noteName = getNoteLetter(note);
		
		var accidental = getAccidentalEdoSteps(note);
		switch (accidental)
		{
			case -7:
				noteName = "v" + noteName + "bb";
				break;
			
			case -6:
				noteName += "bb";
				break
			
			case -5:
				noteName = "^" + noteName + "bb";
				break;
			
			case -4:
				noteName = "v" + noteName + "b";
				break;
			
			case -3:
				noteName += "b";
				break;
			
			case -2:
				noteName = "^" + noteName + "b";
				break;
			
			case -1:
				noteName = "v" + noteName;
				break;
			
			case 0:
				break;
			
			case 1:
				noteName += "^";
				break;
			
			case 2:
				noteName = "v" + noteName + "#";
				break;
			
			case 3:
				noteName += "#";
				break;
			
			case 4:
				noteName = "^" + noteName + "#";
				break;
			
			case 5:
				noteName = "v" + noteName + "x";
				break;
			
			case 6:
				noteName += "x";
				break;
			
			case 7:
				noteName = "^" + noteName + "x";
				break;
			
			default:
				throw "Unsupported accidental: " + accidental;
		}
		
		return noteName;
	}
	
	/**
	 * Return the english note name for the input note.
	 */
	function getNoteLetter(note)
	{
		switch (note.tpc % 7)
		{
			case 0:
				return "C";
			
			case 1:
				return "G";
			
			case 2:
				return "D";
			
			case 3:
				return "A";
			
			case 4:
				return "E";
			
			case 5:
				return "B";
			
			case -1:
			case 6:
				return "F";
			
			default:
				throw "Could not resolve the tpc: " + note.tpc;
		}
	}
	
	/**
	 * Return the number of 22EDO steps this note is altered by.
	 */
	function getAccidentalEdoSteps(note)
	{
		var accidental = supportedAccidentals[getAccidentalName(note)]["EDO_STEPS"];
		if (accidental !== undefined)
		{
			return accidental;
		}
		else
		{
			throw "Could not find the following accidental in the accidentals mapping: " + note.accidentalType;
		}
	}
	
	/**
	 * Return the name of the input note's accidental for the supported
	 * accidentals.
	 */
	function getAccidentalName(note)
	{
		// Casting the accidentalType as a string is necessary to obtain the
		// number corresponding to the enum value.  Parsing it as an int is
		// needed to properly compare it with the enum values in a switch
		// statement.
		var accidentalType = parseInt("" + note.accidentalType);
		// In Musescore3 the accidentalType property is a signed integer, while
		// the Accidentals enum values are always positive.  If it's negative,
		// convert it to an unsigned 8 bit integer by shifting it by 256.
		if (accidentalType < 0)
		{
			accidentalType += 256;
		}
		if ((accidentalType < 0) || (accidentalType >= 256))
		{
			throw "Out of bound accidental type: " + accidentalType;
		}
		switch (accidentalType)
		{
			case Accidental.NONE:
				return "NONE";
			
			case Accidental.FLAT:
				return "FLAT";
			
			case Accidental.NATURAL:
				return "NATURAL";
			
			case Accidental.SHARP:
				return "SHARP";
			
			case Accidental.SHARP2:
				return "SHARP2";
			
			case Accidental.FLAT2:
				return "FLAT2";
			
			case Accidental.FLAT_ARROW_UP:
				return "FLAT_ARROW_UP";
			
			case Accidental.FLAT_ARROW_DOWN:
				return "FLAT_ARROW_DOWN";
			
			case Accidental.NATURAL_ARROW_UP:
				return "NATURAL_ARROW_UP";
			
			case Accidental.NATURAL_ARROW_DOWN:
				return "NATURAL_ARROW_DOWN";
			
			case Accidental.SHARP_ARROW_UP:
				return "SHARP_ARROW_UP";
			
			case Accidental.SHARP_ARROW_DOWN:
				return "SHARP_ARROW_DOWN";
			
			case Accidental.SHARP2_ARROW_UP:
				return "SHARP2_ARROW_UP";
			
			case Accidental.SHARP2_ARROW_DOWN:
				return "SHARP2_ARROW_DOWN";
			
			case Accidental.FLAT2_ARROW_UP:
				return "FLAT2_ARROW_UP";
			
			case Accidental.FLAT2_ARROW_DOWN:
				return "FLAT2_ARROW_DOWN";
			
			case Accidental.DOUBLE_FLAT_ONE_ARROW_DOWN:
				return "DOUBLE_FLAT_ONE_ARROW_DOWN";
			
			case Accidental.FLAT_ONE_ARROW_DOWN:
				return "FLAT_ONE_ARROW_DOWN";
			
			case Accidental.NATURAL_ONE_ARROW_DOWN:
				return "NATURAL_ONE_ARROW_DOWN";
			
			case Accidental.SHARP_ONE_ARROW_DOWN:
				return "SHARP_ONE_ARROW_DOWN";
			
			case Accidental.DOUBLE_SHARP_ONE_ARROW_DOWN:
				return "DOUBLE_SHARP_ONE_ARROW_DOWN";
			
			case Accidental.DOUBLE_FLAT_ONE_ARROW_UP:
				return "DOUBLE_FLAT_ONE_ARROW_UP";
			
			case Accidental.FLAT_ONE_ARROW_UP:
				return "FLAT_ONE_ARROW_UP";
			
			case Accidental.NATURAL_ONE_ARROW_UP:
				return "NATURAL_ONE_ARROW_UP";
			
			case Accidental.SHARP_ONE_ARROW_UP:
				return "SHARP_ONE_ARROW_UP";
			
			case Accidental.DOUBLE_SHARP_ONE_ARROW_UP:
				return "DOUBLE_SHARP_ONE_ARROW_UP";
			
			default:
				throw "Unsupported accidental: " + note.accidentalType;
		}
	}
	
	/**
	 * Log the input message, prefixed by the timestamp.  Automatically redirect
	 * the output message depending on the MuseScore version.
	 */
	function logMessage(message, isErrorMessage)
	{
		if (isErrorMessage === undefined)
		{
			isErrorMessage = false;
		}
	
		var formattedMessage = Qt.formatDateTime(new Date(), "yyyy-MM-dd HH:mm:ss") + " | " + message;
		if (mscoreMajorVersion >= 4)
		{
			debugLogger.log(formattedMessage, isErrorMessage);
		}
		else
		{
			console.log(formattedMessage);	
		}
	}
}


--Abhay Lodhi
CREATE PROCEDURE AllocateSubjects
AS
BEGIN
    DECLARE @student_id INT;
    DECLARE @gpa DECIMAL(3,2);
    DECLARE @pref_subject_id VARCHAR(10);
    DECLARE @pref_num INT;
    DECLARE @seat_count INT;
    DECLARE @done INT;
    DECLARE @preference_cursor CURSOR;

    -- Temporary table to store preferences
    IF OBJECT_ID('tempdb..#TempPreferences') IS NOT NULL
    BEGIN
        DROP TABLE #TempPreferences;
    END;

    CREATE TABLE #TempPreferences (
        StudentId INT,
        SubjectId VARCHAR(10),
        Preference INT
    );

    -- Copy preferences to temporary table
    INSERT INTO #TempPreferences
    SELECT StudentId, SubjectId, Preference
    FROM StudentPreference;

    -- Cursor for iterating through students sorted by GPA
    DECLARE student_cursor CURSOR FOR 
    SELECT StudentId, GPA 
    FROM StudentDetails 
    ORDER BY GPA DESC;

    -- Open the student cursor
    OPEN student_cursor;
    FETCH NEXT FROM student_cursor INTO @student_id, @gpa;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Reset the done flag for the preference cursor
        SET @done = 0;

        -- Open the preference cursor for the current student
        SET @preference_cursor = CURSOR FOR 
            SELECT SubjectId, Preference 
            FROM #TempPreferences 
            WHERE StudentId = @student_id 
            ORDER BY Preference ASC;

        OPEN @preference_cursor;
        FETCH NEXT FROM @preference_cursor INTO @pref_subject_id, @pref_num;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Check if the subject has available seats
            SELECT @seat_count = RemainingSeats
            FROM SubjectDetails
            WHERE SubjectId = @pref_subject_id;

            IF @seat_count > 0
            BEGIN
                -- Allocate subject to student
                INSERT INTO Allotments (SubjectId, StudentId)
                VALUES (@pref_subject_id, @student_id);

                -- Decrease the number of remaining seats
                UPDATE SubjectDetails
                SET RemainingSeats = RemainingSeats - 1
                WHERE SubjectId = @pref_subject_id;

                -- Set the done flag and break out of the preference loop
                SET @done = 1;
                BREAK;
            END;

            FETCH NEXT FROM @preference_cursor INTO @pref_subject_id, @pref_num;
        END;

        -- Close and deallocate the preference cursor
        CLOSE @preference_cursor;
        DEALLOCATE @preference_cursor;

        -- If student is not allocated, add to UnallotedStudents
        IF @done = 0
        BEGIN
            INSERT INTO UnallotedStudents (StudentId)
            VALUES (@student_id);
        END;

        -- Fetch the next student
        FETCH NEXT FROM student_cursor INTO @student_id, @gpa;
    END;

    -- Close and deallocate the student cursor
    CLOSE student_cursor;
    DEALLOCATE student_cursor;

    -- Clean up temporary table
    DROP TABLE #TempPreferences;
END;
GO
--LMS_ID-CT_CSI_SQ_2899
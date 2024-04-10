const express = require('express');
const mysql = require('mysql');
const cors = require('cors');
const path = require('path');

const app = express();

app.use(express.static(path.join( __dirname , 'public')));
app.use(cors());
app.use(express.json());

const port = 5001;

const db = mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'leave_management'
    
});
//console.log('this runs')

app.get('/userVerify', (req, res) => {
    res.json('Hello World');
});

app.post('/userVerify', (req, res) => {
    const user_id= req.body.user_id;
    const passwd = req.body.passwd;
    const role = req.body.role;
    //console.log('this runs')
    sql = 'SELECT * FROM auth WHERE user_id = ? AND passwd = ? AND role = ?';
    db.query(sql, [user_id, passwd, role], (err, result) => {
        if(err){
            res.send({err: err});
        }

        if(result.length > 0){
            res.send(result);
        } else {
            res.send({message: 'Wrong user_id or password'});
        }
    });
});

app.get('/studentData', (req, res) => {
    const user_id = req.query.user_id;
    const responseData = {};

    // Fetch student data
    db.query('SELECT * FROM students WHERE roll_no = ?', user_id, (err, studentResult) => {
        if (err) {
            res.status(500).send({ error: err });
            return;
        }

        if (studentResult.length > 0) {
            responseData.studentData = studentResult[0]; // Assuming there's only one student with the given ID
        } else {
            res.status(404).send({ message: 'Student not found' });
            return;
        }

        // Fetch leave data
        db.query('SELECT * FROM leaves WHERE user_id = ?', user_id, (err, leaveResult) => {
            if (err) {
                res.status(500).send({ error: err });
                return;
            }

            responseData.leaveData = leaveResult;

            // Fetch student enrollment data
            db.query('SELECT * FROM student_enrollment WHERE roll_no = ?', user_id, (err, enrollmentResult) => {
                if (err) {
                    res.status(500).send({ error: err });
                    return;
                }

                responseData.enrollmentData = enrollmentResult;

                res.status(200).send(responseData);
            });
        });
    });
});

app.get('/instructorData', (req, res) => {
    const user_id = req.query.user_id;
    const responseData = {};

    // Fetch student data
    db.query('SELECT * FROM course_instructors WHERE rg_no = ?', user_id, (err, instructorResult) => {
        if (err) {
            res.status(500).send({ error: err });
            return;
        }

        if (instructorResult.length > 0) {
            responseData.instructorData = instructorResult[0];
        } else {
            res.status(404).send({ message: 'Student not found' });
            return;
        }

            // Fetch leave data
            db.query('SELECT * FROM leaves WHERE user_id = ?', user_id, (err, leaveResult) => {
                if (err) {
                    res.status(500).send({ error: err });
                    return;
                }

                responseData.leaveData = leaveResult;

            // Fetch course data corresponding to the instructor
            db.query('SELECT * FROM courses WHERE instructor_rg_no = ?', user_id, (err, courseResult) => {
                if (err) {
                    res.status(500).send({ error: err });
                    return;
                }

                responseData.courseData = courseResult;

                res.status(200).send(responseData);
            });
        });
    });
});

app.post('/addLeave', (req, res) => {
    //console.log('this runs')
    const leave_date = req.body.leave_date;
    const reason = req.body.reason;
    const user_id = req.body.user_id;
    const user_role = req.body.user_role;
    const leave_status = 'pending';
    const course_code = req.body.course_code;

    db.query('INSERT INTO leave_management.leaves (leave_date, reason, user_id, user_role, status, course_code) VALUES (?, ?, ?, ?, ?, ?)',
        [leave_date, reason, user_id, user_role, leave_status, course_code], (err, result) => {
            if (err) {
                res.status(500).send({ error: err });
                return;
            }

            res.status(200).send({ message: 'Leave added successfully' });
        });
});

app.post('/addUser', (req, res) => {
    const user_id = req.body.user_id;
    const passwd = req.body.passwd;
    const role = req.body.role;

    db.query('INSERT INTO leave_management.auth (user_id, passwd, role) VALUES (?, ?, ?)',
        [user_id, passwd, role], (err, result) => {
            if (err) {
                res.status(500).send({ error: err });
                return;
            }
        });
    
    if(role=='student'){
        const roll_no = req.body.user_id;
        const name = req.body.name;
        const branch = req.body.branch;
        const stream = req.body.stream;
        const joining_year = req.body.joining_year;

        db.query('INSERT INTO leave_management.students (roll_no, name, branch, stream, joining_year) VALUES (?, ?, ?, ?, ?)',
            [roll_no, name, branch, stream, joining_year], (err, result) => {
                if (err) {
                    res.status(500).send({ error: err });
                    return;
                }

                res.status(200).send({ message: 'Student added successfully' });
            });
    }else if(role=='course instructor'){
        const rg_no = req.body.user_id;
        const name = req.body.name;
        const dept = req.body.branch;

        db.query('INSERT INTO leave_management.course_instructors (rg_no, name, dept) VALUES (?, ?, ?)',
            [rg_no, name, dept], (err, result) => {
                if (err) {
                    res.status(500).send({ error: err });
                    return;
                }

                res.status(200).send({ message: 'Course Instructor added successfully' });
            });
    }

});

app.get('/getLeaves', (req, res) => {
    const course_code = req.query.course_code;
    const responseData = {};

    db.query('SELECT * FROM leaves WHERE course_code = ?', course_code, (err, leaveResult) => {
        if (err) {
            res.status(500).send({ error: err });
            return;
        }

        responseData.leaveData = leaveResult;

        res.status(200).send(responseData);
    });
});

app.post('/rejectLeave', (req, res) => {
    const leave_id = req.body.leave_id;
    

    db.query("UPDATE leave_management.leaves SET leaves.status = 'rejected' WHERE leaves.leave_id = ?",
        [leave_id], (err, result) => {
            if (err) {
                res.status(500).send({ error: err });
                return;
            }

            res.status(200).send({ message: 'Leave rejected successfully' });
        });
});

app.post('/approveLeave', (req, res) => {
    const leave_id = req.body.leave_id;
    //console.log(leave_id)
    db.query("UPDATE leave_management.leaves SET leaves.status = 'accepted' WHERE leaves.leave_id = ?",
        [leave_id], (err, result) => {
            if (err) {
                res.status(500).send({ error: err });
                return;
            }

            res.status(200).send({ message: 'Leave approved successfully' });
        });
});

app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
});
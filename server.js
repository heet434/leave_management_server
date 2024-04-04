const express = require('express');
const mysql = require('mysql');
const cors = require('cors');
const path = require('path');

const app = express();

app.use(express.static(path.join( __dirname , 'public')));
app.use(cors());
app.use(express.json());

const port = process.env.PORT || 5001;

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
            console.log(result + 'logged in');
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


app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
});
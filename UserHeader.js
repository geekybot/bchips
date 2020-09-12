
import React from "react";

// reactstrap components
import { Button, Container, Row, Col } from "reactstrap";

class UserHeader extends React.Component {
  render() {
    return (
      <>
        <div
          className="header  align-items-center"
          style={{
           minHeight: "400px",
            backgroundImage:
          "url(" + require("assets/img/theme/scott-graham-5fNmWej4tAA-unsplash.jpg") + ")",
             ackgroundSize: "cover",
             backgroundPosition: "center top"
         }}
        >
        
          {/* Mask */}
          <span className="mask bg-gradient-default opacity-4" />
          {/* Header container */}
          <Container className="d-flex align-items-center" fluid>
            <Row>
              <Col lg="7" md="10">
               </Col>
            </Row>
          </Container>
        </div>
      </>
    );
  }
}

export default UserHeader;
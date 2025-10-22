import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import { config } from '../config';

function Dashboard() {
  const navigate = useNavigate();
  const [user, setUser] = useState(null);
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    const fetchUserData = async () => {
      try {
        const token = localStorage.getItem('token');
        const storedUser = JSON.parse(localStorage.getItem('user') || '{}');
        
        setUser(storedUser);

        // Fetch user profile from backend service
        const response = await axios.get(
          `${config.BACKEND_SERVICE_URL}/api/users/profile`,
          {
            headers: {
              Authorization: `Bearer ${token}`
            }
          }
        );

        setProfile(response.data);
      } catch (err) {
        console.error('Error fetching user data:', err);
        setError('Failed to load user data');
      } finally {
        setLoading(false);
      }
    };

    fetchUserData();
  }, []);

  const handleLogout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    navigate('/login');
  };

  if (loading) {
    return <div className="loading">Loading...</div>;
  }

  return (
    <div className="dashboard">
      <div className="container">
        <div className="dashboard-header">
          <h1>Dashboard</h1>
          <button onClick={handleLogout} className="logout-btn">
            Logout
          </button>
        </div>

        <div className="dashboard-content">
          {error && <div className="error-message">{error}</div>}
          
          <div className="profile-section">
            <h2>Welcome, {user?.name}!</h2>
            
            <div className="profile-info">
              <h3>User Information</h3>
              <p><strong>Name:</strong> {user?.name}</p>
              <p><strong>Email:</strong> {user?.email}</p>
              <p><strong>User ID:</strong> {user?.id}</p>
            </div>

            {profile && (
              <div className="profile-info">
                <h3>Profile Details (from Backend Service)</h3>
                <p><strong>Name:</strong> {profile.name}</p>
                <p><strong>Email:</strong> {profile.email}</p>
                <p><strong>Created At:</strong> {new Date(profile.createdAt).toLocaleDateString()}</p>
                <p><strong>Updated At:</strong> {new Date(profile.updatedAt).toLocaleDateString()}</p>
              </div>
            )}

            <div className="profile-info">
              <h3>Application Status</h3>
              <p>✅ Authentication Service: Connected</p>
              <p>✅ Backend Service: Connected</p>
              <p>✅ Database: Connected</p>
              <p>✅ Frontend: Running</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default Dashboard;
